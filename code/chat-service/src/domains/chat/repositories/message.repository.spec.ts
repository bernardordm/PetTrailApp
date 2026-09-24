import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { MessageRepository } from './message.repository';
import { MessageEntity } from '../entities/message.entity';

const mockTypeOrmRepo = () => ({
  create: jest.fn(),
  save: jest.fn(),
  findOne: jest.fn(),
  findAndCount: jest.fn(),
  createQueryBuilder: jest.fn(),
});

describe('MessageRepository', () => {
  let repo: MessageRepository;
  let orm: ReturnType<typeof mockTypeOrmRepo>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        MessageRepository,
        { provide: getRepositoryToken(MessageEntity), useFactory: mockTypeOrmRepo },
      ],
    }).compile();

    repo = module.get(MessageRepository);
    orm = module.get(getRepositoryToken(MessageEntity));
  });

  describe('create', () => {
    it('saves a new message', async () => {
      const data = {
        identifier: 'm1',
        tour_id: 't1',
        sender_id: 'u1',
        content: 'hello',
        sent_at: new Date('2026-05-13T10:00:00Z'),
      };
      orm.create.mockReturnValue(data);
      orm.save.mockResolvedValue(data);

      await repo.create(data);

      expect(orm.create).toHaveBeenCalledWith(data);
      expect(orm.save).toHaveBeenCalledWith(data);
    });
  });

  describe('findAfter', () => {
    it('returns empty array when lastReceivedId not found', async () => {
      orm.findOne.mockResolvedValue(null);
      const result = await repo.findAfter('t1', 'nonexistent');
      expect(result).toEqual([]);
    });

    it('queries messages after the last received sent_at', async () => {
      const lastMsg = { identifier: 'm1', sent_at: new Date('2026-05-13T10:00:00Z') };
      const laterMsgs = [{ identifier: 'm2' }];
      orm.findOne.mockResolvedValue(lastMsg);

      const qb = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue(laterMsgs),
      };
      orm.createQueryBuilder.mockReturnValue(qb);

      const result = await repo.findAfter('t1', 'm1');

      expect(qb.where).toHaveBeenCalledWith('m.tour_id = :tourId', { tourId: 't1' });
      expect(qb.andWhere).toHaveBeenCalledWith('m.sent_at > :sentAt', { sentAt: lastMsg.sent_at });
      expect(result).toBe(laterMsgs);
    });
  });

  describe('findPaginated', () => {
    it('returns messages and total for first page', async () => {
      const messages = [{ identifier: 'm1' }, { identifier: 'm2' }];
      orm.findAndCount.mockResolvedValue([messages, 2]);

      const result = await repo.findPaginated('t1', 1, 30);

      expect(orm.findAndCount).toHaveBeenCalledWith({
        where: { tour_id: 't1' },
        order: { sent_at: 'ASC' },
        skip: 0,
        take: 30,
      });
      expect(result).toEqual({ messages, total: 2 });
    });

    it('skips correctly for page 2', async () => {
      orm.findAndCount.mockResolvedValue([[], 5]);
      await repo.findPaginated('t1', 2, 10);
      expect(orm.findAndCount).toHaveBeenCalledWith(
        expect.objectContaining({ skip: 10, take: 10 }),
      );
    });
  });
});
