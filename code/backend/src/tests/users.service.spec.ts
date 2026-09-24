import { Test } from '@nestjs/testing';
import { ConflictException, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../domains/users/services/users.service';
import { UserRepository } from '../domains/users/repositories/user.repository';
import { UserRole } from '../domains/users/interfaces/user.interface';

jest.mock('bcrypt');
jest.mock('@paralleldrive/cuid2', () => ({ createId: () => 'generated-id' }));

const mockUser = {
  identifier: 'user-1',
  name: 'João',
  email: 'joao@example.com',
  role: UserRole.TUTOR,
};

describe('UsersService', () => {
  let service: UsersService;
  let repo: jest.Mocked<UserRepository>;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: UserRepository,
          useValue: {
            findByEmail: jest.fn(),
            findById: jest.fn(),
            findAll: jest.fn(),
            createWithProfile: jest.fn(),
            update: jest.fn(),
            delete: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(UsersService);
    repo = module.get(UserRepository);
  });

  it('lança ConflictException quando o email já está em uso', async () => {
    repo.findByEmail.mockResolvedValue(mockUser as any);
    await expect(
      service.create({
        name: 'João',
        email: 'joao@example.com',
        password: '123',
        role: UserRole.TUTOR,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('faz hash da senha e chama createWithProfile', async () => {
    repo.findByEmail.mockResolvedValue(null);
    (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-pw');
    repo.createWithProfile.mockResolvedValue(mockUser as any);

    const result = await service.create({
      name: 'João',
      email: 'joao@example.com',
      password: 'senha-plain',
      role: UserRole.TUTOR,
    });

    expect(bcrypt.hash).toHaveBeenCalledWith('senha-plain', 10);
    expect(result).toBe(mockUser);
  });

  it('lança NotFoundException quando o usuário não existe', async () => {
    repo.findById.mockResolvedValue(null);
    await expect(service.findOne('missing')).rejects.toThrow(NotFoundException);
  });

  it('faz hash da nova senha antes de atualizar', async () => {
    repo.findById.mockResolvedValue(mockUser as any);
    (bcrypt.hash as jest.Mock).mockResolvedValue('nova-hashed-pw');
    repo.update.mockResolvedValue(undefined);

    await service.update('user-1', { password: 'nova-senha' });

    expect(bcrypt.hash).toHaveBeenCalledWith('nova-senha', 10);
    expect(repo.update).toHaveBeenCalledWith('user-1', {
      password: 'nova-hashed-pw',
    });
  });

  it('chama delete quando o usuário existe', async () => {
    repo.findById.mockResolvedValue(mockUser as any);
    repo.delete.mockResolvedValue(undefined);

    await service.remove('user-1');

    expect(repo.delete).toHaveBeenCalledWith('user-1');
  });
});
