import { Test } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from '../domains/auth/services/auth.service';
import { UserRepository } from '../domains/users/repositories/user.repository';
import { UserRole } from '../domains/users/interfaces/user.interface';

jest.mock('bcrypt');

const mockUser = {
  identifier: 'user-1',
  name: 'João',
  email: 'joao@example.com',
  password: 'hashed-pw',
  role: UserRole.TUTOR,
};

describe('AuthService', () => {
  let service: AuthService;
  let repo: jest.Mocked<UserRepository>;
  let jwtService: jest.Mocked<JwtService>;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: UserRepository,
          useValue: { findByEmail: jest.fn() },
        },
        {
          provide: JwtService,
          useValue: { sign: jest.fn().mockReturnValue('jwt-token') },
        },
      ],
    }).compile();

    service = module.get(AuthService);
    repo = module.get(UserRepository);
    jwtService = module.get(JwtService);
  });

  describe('validateUser', () => {
    it('lança UnauthorizedException quando usuário não existe', async () => {
      repo.findByEmail.mockResolvedValue(null);
      await expect(service.validateUser('missing@x.com', 'pw')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('lança UnauthorizedException quando a senha não corresponde', async () => {
      repo.findByEmail.mockResolvedValue(mockUser as any);
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.validateUser('joao@example.com', 'errada'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('retorna o usuário quando as credenciais são válidas', async () => {
      repo.findByEmail.mockResolvedValue(mockUser as any);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      const result = await service.validateUser('joao@example.com', 'senha');

      expect(result).toBe(mockUser);
    });
  });

  describe('login', () => {
    it('retorna o payload de login com JWT assinado', () => {
      const result = service.login(mockUser as any);

      expect(jwtService.sign).toHaveBeenCalledWith({
        sub: 'user-1',
        role: UserRole.TUTOR,
      });
      expect(result).toEqual({
        identifier: 'user-1',
        name: 'João',
        email: 'joao@example.com',
        role: UserRole.TUTOR,
        accessToken: 'jwt-token',
      });
    });
  });
});
