import { Test } from '@nestjs/testing';
import { ChatService } from './chat.service';
import { TourRepository } from '../tours/repositories/tour.repository';
import { MessageRepository } from './repositories/message.repository';
import { TourStatus } from '../tours/enums/tour-status.enum';

const makeTour = (overrides: object) => ({
  identifier: 't1',
  status: TourStatus.IN_PROGRESS,
  walker_identifier: 'w1',
  tutor_identifier: 'tu1',
  ...overrides,
});

describe('ChatService', () => {
  let service: ChatService;
  let tourRepo: jest.Mocked<TourRepository>;
  let messageRepo: jest.Mocked<MessageRepository>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        ChatService,
        {
          provide: TourRepository,
          useValue: { findById: jest.fn() },
        },
        {
          provide: MessageRepository,
          useValue: {
            create: jest.fn(),
            findAfter: jest.fn(),
            findPaginated: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(ChatService);
    tourRepo = module.get(TourRepository);
    messageRepo = module.get(MessageRepository);
  });

  describe('validateTourAccess', () => {
    it('returns TOUR_NOT_FOUND when tour does not exist', async () => {
      tourRepo.findById.mockResolvedValue(null);
      expect(await service.validateTourAccess('t1', 'u1')).toEqual({
        ok: false,
        code: 'TOUR_NOT_FOUND',
        message: 'Tour não encontrado',
      });
    });

    it('returns CHAT_NOT_AVAILABLE for WAITING_ACCEPTANCE status', async () => {
      tourRepo.findById.mockResolvedValue(
        makeTour({ status: TourStatus.WAITING_ACCEPTANCE }) as any,
      );
      const result = await service.validateTourAccess('t1', 'w1');
      expect(result).toEqual({
        ok: false,
        code: 'CHAT_NOT_AVAILABLE',
        message: 'Chat não disponível para este status',
      });
    });

    it('returns CHAT_NOT_AVAILABLE for FINISHED status', async () => {
      tourRepo.findById.mockResolvedValue(
        makeTour({ status: TourStatus.FINISHED }) as any,
      );
      const result = await service.validateTourAccess('t1', 'w1');
      expect(result).toEqual({
        ok: false,
        code: 'CHAT_NOT_AVAILABLE',
        message: 'Chat não disponível para este status',
      });
    });

    it('returns CHAT_NOT_AVAILABLE for REFUSED status', async () => {
      tourRepo.findById.mockResolvedValue(
        makeTour({ status: TourStatus.REFUSED }) as any,
      );
      const result = await service.validateTourAccess('t1', 'w1');
      expect(result.code).toBe('CHAT_NOT_AVAILABLE');
    });

    it('returns UNAUTHORIZED when user is neither walker nor tutor', async () => {
      tourRepo.findById.mockResolvedValue(makeTour({}) as any);
      expect(await service.validateTourAccess('t1', 'stranger')).toEqual({
        ok: false,
        code: 'UNAUTHORIZED',
        message: 'Usuário não pertence a este tour',
      });
    });

    it('returns ok when user is the walker', async () => {
      tourRepo.findById.mockResolvedValue(makeTour({}) as any);
      expect(await service.validateTourAccess('t1', 'w1')).toEqual({ ok: true });
    });

    it('returns ok when user is the tutor', async () => {
      tourRepo.findById.mockResolvedValue(
        makeTour({ status: TourStatus.WALKER_ON_THE_WAY }) as any,
      );
      expect(await service.validateTourAccess('t1', 'tu1')).toEqual({ ok: true });
    });
  });

  describe('persistMessage', () => {
    it('delegates to messageRepository.create', async () => {
      const data = {
        identifier: 'm1',
        tour_id: 't1',
        sender_id: 'u1',
        content: 'hello',
        sent_at: new Date(),
      };
      await service.persistMessage(data);
      expect(messageRepo.create).toHaveBeenCalledWith(data);
    });
  });

  describe('getMissedMessages', () => {
    it('delegates to messageRepository.findAfter', async () => {
      const msgs = [{ identifier: 'm2' }] as any[];
      messageRepo.findAfter.mockResolvedValue(msgs);
      const result = await service.getMissedMessages('t1', 'm1');
      expect(result).toBe(msgs);
      expect(messageRepo.findAfter).toHaveBeenCalledWith('t1', 'm1');
    });
  });

  describe('prepareMessage', () => {
    it('returns a string identifier and a Date for sent_at', async () => {
      const result = await service.prepareMessage({
        tour_id: 't1',
        sender_id: 'u1',
        content: 'hi',
      });
      expect(typeof result.identifier).toBe('string');
      expect(result.identifier.length).toBeGreaterThan(0);
      expect(result.sent_at).toBeInstanceOf(Date);
    });
  });
});
