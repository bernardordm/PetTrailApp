import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TourEntity } from '../tours/entities/tour.entity';
import { MessageRepository } from './repositories/message.repository';
import { MessageEntity } from './entities/message.entity';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(TourEntity)
    private readonly tourRepo: Repository<TourEntity>,
    private readonly messageRepository: MessageRepository,
  ) {}

  async getHistory(
    tourId: string,
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ messages: MessageEntity[]; total: number }> {
    const tour = await this.tourRepo.findOne({ where: { identifier: tourId } });
    if (!tour) throw new NotFoundException('Tour não encontrado');

    if (tour.walker_identifier !== userId && tour.tutor_identifier !== userId) {
      throw new ForbiddenException('Acesso negado');
    }

    return this.messageRepository.findPaginated(tourId, page, limit);
  }
}
