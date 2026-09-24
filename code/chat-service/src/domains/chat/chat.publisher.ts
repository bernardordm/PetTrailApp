import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import * as amqplib from 'amqplib';
import {
  getChatDlqAssertOptions,
  getChatQueueAssertOptions,
} from './chat-queue.config';
import { IChatMessagePayload } from './interfaces/chat.interface';

@Injectable()
export class ChatPublisher implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ChatPublisher.name);
  private connection: Awaited<ReturnType<typeof amqplib.connect>>;
  private channel: amqplib.ConfirmChannel;

  private readonly url = process.env.RABBITMQ_URL!;
  private readonly queue = process.env.RABBITMQ_CHAT_QUEUE!;
  private readonly dlq = process.env.RABBITMQ_CHAT_DLQ!;

  async onModuleInit() {
    this.connection = await amqplib.connect(this.url);
    this.channel = await this.connection.createConfirmChannel();
    await this.channel.assertQueue(this.dlq, getChatDlqAssertOptions());
    await this.channel.assertQueue(
      this.queue,
      getChatQueueAssertOptions(this.dlq),
    );
    this.logger.log('ChatPublisher conectado ao RabbitMQ');
  }

  async publish(payload: IChatMessagePayload): Promise<void> {
    this.channel.publish(
      '',
      this.queue,
      Buffer.from(JSON.stringify(payload)),
      { persistent: true },
    );
    await this.channel.waitForConfirms();
    this.logger.log(`Mensagem publicada — tour ${payload.tour_id}`);
  }

  async onModuleDestroy() {
    await this.channel?.close();
    await this.connection?.close();
  }
}
