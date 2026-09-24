import { Logger } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { JwtService } from '@nestjs/jwt';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { ChatPublisher } from './chat.publisher';
import { JoinTourDto } from './dtos/join-tour.dto';
import { SendMessageDto } from './dtos/send-message.dto';

@WebSocketGateway({ cors: { origin: '*' } })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly chatService: ChatService,
    private readonly chatPublisher: ChatPublisher,
  ) {}

  async handleConnection(client: Socket) {
    const raw = (client.handshake.auth as any)?.token as string | undefined
      ?? (client.handshake.headers?.authorization as string | undefined);
    const token = raw?.startsWith('Bearer ') ? raw.slice(7) : raw;

    if (!token) {
      client.emit('auth_error', { message: 'Token não fornecido' });
      client.disconnect(true);
      return;
    }

    try {
      const payload = this.jwtService.verify<{ sub: string; role: string }>(token);
      client.data.user = { identifier: payload.sub, role: payload.role };
      this.logger.log(`Client conectado: ${payload.sub}`);
    } catch {
      client.emit('auth_error', { message: 'Token inválido ou expirado' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client desconectado: ${client.id}`);
  }

  @SubscribeMessage('join_tour')
  async handleJoinTour(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: JoinTourDto,
  ) {
    const user = client.data.user;
    const validation = await this.chatService.validateTourAccess(
      dto.tour_id,
      user.identifier,
    );
    if (!validation.ok) {
      client.emit('message_error', {
        code: validation.code,
        message: validation.message,
      });
      return;
    }

    await client.join(`tour:${dto.tour_id}`);

    if (dto.last_received_id) {
      const missed = await this.chatService.getMissedMessages(
        dto.tour_id,
        dto.last_received_id,
      );
      client.emit('missed_messages', { messages: missed });
    } else {
      const { messages } = await this.chatService.getHistory(dto.tour_id, 1, 100);
      client.emit('missed_messages', { messages });
    }
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: SendMessageDto,
  ) {
    const user = client.data.user;
    const validation = await this.chatService.validateTourAccess(
      dto.tour_id,
      user.identifier,
    );
    if (!validation.ok) {
      client.emit('message_error', {
        code: validation.code,
        message: validation.message,
      });
      return;
    }

    const { identifier, sent_at } = await this.chatService.prepareMessage({
      tour_id: dto.tour_id,
      sender_id: user.identifier,
      content: dto.content,
    });

    try {
      await this.chatPublisher.publish({
        identifier,
        tour_id: dto.tour_id,
        sender_id: user.identifier,
        content: dto.content,
        sent_at,
      });
      client.emit('message_ack', {
        client_temp_id: dto.client_temp_id,
        identifier,
        sent_at,
      });
    } catch {
      client.emit('message_error', {
        code: 'SEND_FAILED',
        message: 'Falha ao enviar mensagem',
      });
    }
  }

  emitToRoom(room: string, event: string, data: unknown) {
    this.server?.to(room).emit(event, data);
  }
}
