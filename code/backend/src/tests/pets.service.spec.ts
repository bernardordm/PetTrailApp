import { Test } from '@nestjs/testing';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PetsService } from '../domains/pets/services/pets.service';
import { PetRepository } from '../domains/pets/repositories/pet.repository';

jest.mock('@paralleldrive/cuid2', () => ({
  createId: () => 'generated-pet-id',
}));

const mockPet = {
  identifier: 'pet-1',
  name: 'Rex',
  species: 'dog',
  size: 'large',
  age: '3',
  photo_url: null,
  photo_data: null,
  photo_mime_type: null,
  observations: null,
  tutor_identifier: 'tutor-1',
};

describe('PetsService', () => {
  let service: PetsService;
  let repo: jest.Mocked<PetRepository>;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        PetsService,
        {
          provide: PetRepository,
          useValue: {
            findAllByTutor: jest.fn(),
            findById: jest.fn(),
            findPhotoById: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            delete: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(PetsService);
    repo = module.get(PetRepository);
  });

  it('lança NotFoundException quando o pet não existe', async () => {
    repo.findById.mockResolvedValue(null);
    await expect(service.findOne('missing', 'tutor-1')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('lança ForbiddenException quando o tutor não é dono do pet', async () => {
    repo.findById.mockResolvedValue(mockPet as any);
    await expect(service.findOne('pet-1', 'outro-tutor')).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('lança BadRequestException quando o buffer da foto está vazio', async () => {
    repo.findById.mockResolvedValue(mockPet as any);
    await expect(
      service.updatePhoto('pet-1', Buffer.alloc(0), 'image/jpeg', 0, 'tutor-1'),
    ).rejects.toThrow(BadRequestException);
  });

  it('salva a foto e retorna o pet atualizado', async () => {
    const updated = {
      ...mockPet,
      photo_url: '/tutors/tutor-1/pets/pet-1/photo',
    };
    repo.findById
      .mockResolvedValueOnce(mockPet as any)
      .mockResolvedValueOnce(updated as any);
    repo.update.mockResolvedValue(undefined);

    const buffer = Buffer.from('image-bytes');
    const result = await service.updatePhoto(
      'pet-1',
      buffer,
      'image/jpeg',
      buffer.length,
      'tutor-1',
    );

    expect(repo.update).toHaveBeenCalledWith(
      'pet-1',
      expect.objectContaining({
        photo_url: '/tutors/tutor-1/pets/pet-1/photo',
      }),
    );
    expect(result).toHaveProperty(
      'photo_url',
      '/tutors/tutor-1/pets/pet-1/photo',
    );
  });

  it('retorna os dados e o tipo da foto', async () => {
    const photoBuffer = Buffer.from('photo-bytes');
    repo.findPhotoById.mockResolvedValue({
      ...mockPet,
      photo_data: photoBuffer,
      photo_mime_type: 'image/jpeg',
    } as any);

    const result = await service.getPhoto('pet-1', 'tutor-1');
    expect(result).toEqual({ data: photoBuffer, mimeType: 'image/jpeg' });
  });
});
