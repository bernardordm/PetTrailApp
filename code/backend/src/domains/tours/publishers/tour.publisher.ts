import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import * as amqplib from 'amqplib';
import { ICreateTour } from '../interfaces/tour.interface';

@Injectable()
export class TourPublisher implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(TourPublisher.name);
  private connection: Awaited<ReturnType<typeof amqplib.connect>>;
  private channel: amqplib.ConfirmChannel;

  private readonly url = process.env.RABBITMQ_URL!;
  private readonly queue = process.env.RABBITMQ_QUEUE!;

  async onModuleInit() {
    this.connection = await amqplib.connect(this.url);
    this.channel = await this.connection.createConfirmChannel();
    await this.channel.assertQueue(this.queue, { durable: true });
    this.logger.log('Conectado ao RabbitMQ');
  }

  async dispatch(payload: ICreateTour): Promise<void> {
    this.channel.publish('', this.queue, Buffer.from(JSON.stringify(payload)), {
      persistent: true,
    });
    await this.channel.waitForConfirms();
    this.logger.log(
      `tour_requested publicado — walker ${payload.walker_identifier}`,
    );
  }

  async onModuleDestroy() {
    await this.channel?.close();
    await this.connection?.close();
  }
}
