import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MessageEntity } from '../entities/message.entity';

@Injectable()
export class MessageRepository {
  constructor(
    @InjectRepository(MessageEntity)
    private readonly repository: Repository<MessageEntity>,
  ) {}

  async create(data: {
    identifier: string;
    tour_id: string;
    sender_id: string;
    content: string;
    sent_at: Date;
  }): Promise<void> {
    const entity = this.repository.create(data);
    await this.repository.save(entity);
  }

  async findAfter(
    tourId: string,
    lastReceivedId: string,
  ): Promise<MessageEntity[]> {
    const last = await this.repository.findOne({
      where: { identifier: lastReceivedId },
    });
    if (!last) return [];

    return this.repository
      .createQueryBuilder('m')
      .where('m.tour_id = :tourId', { tourId })
      .andWhere('m.sent_at > :sentAt', { sentAt: last.sent_at })
      .orderBy('m.sent_at', 'ASC')
      .getMany();
  }

  async findPaginated(
    tourId: string,
    page: number,
    limit: number,
  ): Promise<{ messages: MessageEntity[]; total: number }> {
    const [messages, total] = await this.repository.findAndCount({
      where: { tour_id: tourId },
      order: { sent_at: 'ASC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { messages, total };
  }
}
