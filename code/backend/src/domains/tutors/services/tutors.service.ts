import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { ITutor, IUpdateTutor } from '../interfaces/tutor.interface';
import { TutorRepository } from '../repositories/tutor.repository';

@Injectable()
export class TutorsService {
  constructor(private readonly tutorRepository: TutorRepository) {}

  async findAll(): Promise<ITutor[]> {
    return this.tutorRepository.findAll();
  }

  async findOne(identifier: string): Promise<ITutor> {
    const tutor = await this.tutorRepository.findById(identifier);
    if (!tutor) throw new NotFoundException('Tutor not found');
    return tutor;
  }

  async update(identifier: string, dto: IUpdateTutor): Promise<ITutor> {
    const tutor = await this.tutorRepository.findById(identifier);
    if (!tutor) throw new NotFoundException('Tutor not found');
    await this.tutorRepository.update(identifier, dto);
    return this.tutorRepository.findById(identifier) as Promise<ITutor>;
  }

  async updatePhoto(
    identifier: string,
    fileBuffer: Buffer,
    mimeType: string,
    fileSize: number,
  ): Promise<ITutor> {
    const tutor = await this.tutorRepository.findById(identifier);
    if (!tutor) throw new NotFoundException('Tutor not found');
    if (!fileBuffer.length) {
      throw new BadRequestException('Arquivo de imagem inválido');
    }

    const photoHash = createHash('sha256').update(fileBuffer).digest('hex');
    const photoUrl = `/tutors/${identifier}/photo`;

    await this.tutorRepository.update(identifier, {
      photo_url: photoUrl,
      photo_data: fileBuffer,
      photo_mime_type: mimeType,
      photo_size: fileSize,
      photo_hash: photoHash,
    });

    return this.tutorRepository.findById(identifier) as Promise<ITutor>;
  }

  async getPhoto(
    identifier: string,
  ): Promise<{ data: Buffer; mimeType: string }> {
    const tutor = await this.tutorRepository.findPhotoById(identifier);
    if (!tutor) throw new NotFoundException('Tutor not found');
    if (!tutor.photo_data || !tutor.photo_mime_type) {
      throw new NotFoundException('Foto do tutor não encontrada');
    }

    return {
      data: tutor.photo_data,
      mimeType: tutor.photo_mime_type,
    };
  }
}
