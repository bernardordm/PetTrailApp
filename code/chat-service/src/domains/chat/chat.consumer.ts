import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import * as amqplib from 'amqplib';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import {
  getChatDlqAssertOptions,
  getChatQueueAssertOptions,
} from './chat-queue.config';
import { IChatMessagePayload } from './interfaces/chat.interface';

@Injectable()
export class ChatConsumer implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ChatConsumer.name);
  private connection: Awaited<ReturnType<typeof amqplib.connect>>;
  private channel: amqplib.Channel;

  private readonly url = process.env.RABBITMQ_URL!;
  private readonly queue = process.env.RABBITMQ_CHAT_QUEUE!;
  private readonly dlq = process.env.RABBITMQ_CHAT_DLQ!;

  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
  ) {}

  async onModuleInit() {
    this.connection = await amqplib.connect(this.url);
    this.channel = await this.connection.createChannel();

    await this.channel.assertQueue(this.dlq, getChatDlqAssertOptions());
    await this.channel.assertQueue(
      this.queue,
      getChatQueueAssertOptions(this.dlq),
    );
    await this.channel.prefetch(1);

    this.logger.log(`Consumindo fila: ${this.queue}`);

    await this.channel.consume(
      this.queue,
      async (msg) => {
        if (!msg?.content) return;

        let payload: IChatMessagePayload;
        try {
          payload = JSON.parse(msg.content.toString()) as IChatMessagePayload;

          await this.chatService.persistMessage(payload);

          this.chatGateway.emitToRoom(`tour:${payload.tour_id}`, 'new_message', {
            identifier: payload.identifier,
            tour_id: payload.tour_id,
            sender_id: payload.sender_id,
            content: payload.content,
            sent_at: payload.sent_at,
          });

          this.channel.ack(msg);
          this.logger.log(`Mensagem processada: ${payload.identifier}`);
        } catch (err: any) {
          this.logger.error(`Erro ao processar mensagem: ${err.message}`);
          this.channel.nack(msg, false, false);
        }
      },
      { noAck: false },
    );
  }

  async onModuleDestroy() {
    await this.channel?.close();
    await this.connection?.close();
  }
}
