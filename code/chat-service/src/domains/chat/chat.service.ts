import { Injectable } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { TourRepository } from '../tours/repositories/tour.repository';
import { MessageRepository } from './repositories/message.repository';
import { MessageEntity } from './entities/message.entity';
import { TourStatus } from '../tours/enums/tour-status.enum';
import { IChatMessagePayload, IValidationResult } from './interfaces/chat.interface';

const CHAT_ACTIVE_STATUSES = [TourStatus.WALKER_ON_THE_WAY, TourStatus.IN_PROGRESS];

@Injectable()
export class ChatService {
  constructor(
    private readonly tourRepository: TourRepository,
    private readonly messageRepository: MessageRepository,
  ) {}

  async validateTourAccess(
    tourId: string,
    userId: string,
  ): Promise<IValidationResult> {
    const tour = await this.tourRepository.findById(tourId);
    if (!tour) {
      return { ok: false, code: 'TOUR_NOT_FOUND', message: 'Tour não encontrado' };
    }
    if (!CHAT_ACTIVE_STATUSES.includes(tour.status)) {
      return { ok: false, code: 'CHAT_NOT_AVAILABLE', message: 'Chat não disponível para este status' };
    }
    if (tour.walker_identifier !== userId && tour.tutor_identifier !== userId) {
      return { ok: false, code: 'UNAUTHORIZED', message: 'Usuário não pertence a este tour' };
    }
    return { ok: true };
  }

  async prepareMessage(data: {
    tour_id: string;
    sender_id: string;
    content: string;
  }): Promise<{ identifier: string; sent_at: Date }> {
    return { identifier: createId(), sent_at: new Date() };
  }

  async persistMessage(data: IChatMessagePayload): Promise<void> {
    await this.messageRepository.create(data);
  }

  async getMissedMessages(
    tourId: string,
    lastReceivedId: string,
  ): Promise<MessageEntity[]> {
    return this.messageRepository.findAfter(tourId, lastReceivedId);
  }

  async getHistory(
    tourId: string,
    page: number,
    limit: number,
  ): Promise<{ messages: MessageEntity[]; total: number }> {
    return this.messageRepository.findPaginated(tourId, page, limit);
  }
}
