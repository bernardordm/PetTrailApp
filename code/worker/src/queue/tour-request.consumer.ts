import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import * as amqplib from 'amqplib';
import { ToursService } from '../domains/tours/services/tours.service';
import { ICreateTour } from '../domains/tours/interfaces/tour.interface';

@Injectable()
export class TourRequestConsumer implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(TourRequestConsumer.name);
  private connection: Awaited<ReturnType<typeof amqplib.connect>>;
  private channel: amqplib.Channel;

  private readonly url = process.env.RABBITMQ_URL!;
  private readonly queue = process.env.RABBITMQ_QUEUE!;

  constructor(private readonly toursService: ToursService) {}

  async onModuleInit() {
    this.connection = await amqplib.connect(this.url);
    this.channel = await this.connection.createChannel();
    await this.channel.assertQueue(this.queue, { durable: true });
    await this.channel.prefetch(1);

    this.logger.log(`Consumindo fila: ${this.queue}`);

    await this.channel.consume(
      this.queue,
      async (msg) => {
        if (!msg?.content) return;

        let payload: ICreateTour;
        try {
          payload = JSON.parse(msg.content.toString()) as ICreateTour;
          this.logger.log(
            `Processando tour — walker ${payload.walker_identifier}`,
          );

          await this.toursService.createTour(payload);

          this.channel.ack(msg);
          this.logger.log(
            `Tour criado com sucesso — walker ${payload.walker_identifier}`,
          );
        } catch (err: any) {
          this.logger.error(`Erro ao processar tour: ${err.message}`);
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
