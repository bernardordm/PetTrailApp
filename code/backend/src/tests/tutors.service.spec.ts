import { Test } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { TutorsService } from '../domains/tutors/services/tutors.service';
import { TutorRepository } from '../domains/tutors/repositories/tutor.repository';

const mockTutor = {
  identifier: 'tutor-1',
  user: {
    identifier: 'tutor-1',
    name: 'Ana',
    email: 'ana@example.com',
    role: 'tutor',
  },
  photo_url: null,
  photo_data: null,
  photo_mime_type: null,
};

describe('TutorsService', () => {
  let service: TutorsService;
  let repo: jest.Mocked<TutorRepository>;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        TutorsService,
        {
          provide: TutorRepository,
          useValue: {
            findAll: jest.fn(),
            findById: jest.fn(),
            findPhotoById: jest.fn(),
            update: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(TutorsService);
    repo = module.get(TutorRepository);
  });

  describe('findOne', () => {
    it('lança NotFoundException quando o tutor não existe', async () => {
      repo.findById.mockResolvedValue(null);
      await expect(service.findOne('missing')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('update', () => {
    it('lança NotFoundException quando o tutor não existe', async () => {
      repo.findById.mockResolvedValue(null);
      await expect(service.update('missing', {})).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('updatePhoto', () => {
    it('lança BadRequestException quando o buffer da foto está vazio', async () => {
      repo.findById.mockResolvedValue(mockTutor as any);
      await expect(
        service.updatePhoto('tutor-1', Buffer.alloc(0), 'image/jpeg', 0),
      ).rejects.toThrow(BadRequestException);
    });

    it('salva a foto e retorna o tutor atualizado', async () => {
      const updated = { ...mockTutor, photo_url: '/tutors/tutor-1/photo' };
      repo.findById
        .mockResolvedValueOnce(mockTutor as any)
        .mockResolvedValueOnce(updated as any);
      repo.update.mockResolvedValue(undefined);

      const buffer = Buffer.from('image-bytes');
      const result = await service.updatePhoto(
        'tutor-1',
        buffer,
        'image/jpeg',
        buffer.length,
      );

      expect(repo.update).toHaveBeenCalledWith(
        'tutor-1',
        expect.objectContaining({
          photo_url: '/tutors/tutor-1/photo',
          photo_mime_type: 'image/jpeg',
        }),
      );
      expect(result).toHaveProperty('photo_url', '/tutors/tutor-1/photo');
    });
  });

  describe('getPhoto', () => {
    it('lança NotFoundException quando o tutor não tem foto', async () => {
      repo.findPhotoById.mockResolvedValue(mockTutor as any);
      await expect(service.getPhoto('tutor-1')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('retorna os dados e o tipo da foto', async () => {
      const photoBuffer = Buffer.from('photo-bytes');
      repo.findPhotoById.mockResolvedValue({
        ...mockTutor,
        photo_data: photoBuffer,
        photo_mime_type: 'image/jpeg',
      } as any);

      const result = await service.getPhoto('tutor-1');
      expect(result).toEqual({ data: photoBuffer, mimeType: 'image/jpeg' });
    });
  });
});
