import { Test } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { WalkersService } from '../domains/walkers/services/walkers.service';
import { WalkerRepository } from '../domains/walkers/repositories/walker.repository';
import { FirebaseService } from '../app/firebase/firebase.service';

const mockWalker = {
  identifier: 'walker-1',
  user: {
    identifier: 'walker-1',
    name: 'Carlos',
    email: 'carlos@example.com',
    role: 'walker',
  },
  photo_url: null,
  photo_data: null,
  photo_mime_type: null,
  available: true,
  status: 'idle' as const,
};

describe('WalkersService', () => {
  let service: WalkersService;
  let repo: jest.Mocked<WalkerRepository>;
  let firebase: jest.Mocked<FirebaseService>;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        WalkersService,
        {
          provide: WalkerRepository,
          useValue: {
            findAll: jest.fn(),
            findById: jest.fn(),
            findByIdForPin: jest.fn(),
            findPhotoById: jest.fn(),
            update: jest.fn(),
          },
        },
        {
          provide: FirebaseService,
          useValue: {
            initWalkerLocation: jest.fn(),
            clearWalkerLocation: jest.fn(),
            updateWalkerCoords: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(WalkersService);
    repo = module.get(WalkerRepository);
    firebase = module.get(FirebaseService);
  });

  it('lança NotFoundException quando o passeador não existe', async () => {
    repo.findById.mockResolvedValue(null);
    await expect(service.findOne('missing')).rejects.toThrow(NotFoundException);
  });

  it('lança BadRequestException quando o buffer da foto está vazio', async () => {
    repo.findById.mockResolvedValue(mockWalker as any);
    await expect(
      service.updatePhoto('walker-1', Buffer.alloc(0), 'image/jpeg', 0),
    ).rejects.toThrow(BadRequestException);
  });

  it('retorna os dados e o tipo da foto', async () => {
    const photoBuffer = Buffer.from('photo-bytes');
    repo.findPhotoById.mockResolvedValue({
      ...mockWalker,
      photo_data: photoBuffer,
      photo_mime_type: 'image/jpeg',
    } as any);

    const result = await service.getPhoto('walker-1');
    expect(result).toEqual({ data: photoBuffer, mimeType: 'image/jpeg' });
  });

  it('ativa disponibilidade e inicializa localização no Firebase', async () => {
    repo.findById
      .mockResolvedValueOnce(mockWalker as any)
      .mockResolvedValueOnce(mockWalker as any);
    repo.update.mockResolvedValue(undefined);
    firebase.initWalkerLocation.mockResolvedValue(undefined);

    await service.activatedAvailable('walker-1', { available: true });

    expect(repo.update).toHaveBeenCalledWith('walker-1', {
      available: true,
      status: 'idle',
    });
    expect(firebase.initWalkerLocation).toHaveBeenCalledWith(
      'walker-1',
      expect.objectContaining({ available: true, status: 'idle' }),
    );
  });

  it('desativa disponibilidade e limpa localização no Firebase', async () => {
    repo.findById
      .mockResolvedValueOnce(mockWalker as any)
      .mockResolvedValueOnce(mockWalker as any);
    repo.update.mockResolvedValue(undefined);
    firebase.clearWalkerLocation.mockResolvedValue(undefined);

    await service.activatedAvailable('walker-1', { available: false });

    expect(repo.update).toHaveBeenCalledWith('walker-1', {
      available: false,
      status: 'idle',
    });
    expect(firebase.clearWalkerLocation).toHaveBeenCalledWith('walker-1');
  });
});
