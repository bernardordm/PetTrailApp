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
