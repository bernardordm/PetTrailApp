import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { createHash } from 'crypto';
import { PetRepository } from '../repositories/pet.repository';
import { ICreatePet, IPet, IUpdatePet } from '../interfaces/pet.interface';

@Injectable()
export class PetsService {
  constructor(private readonly petRepository: PetRepository) {}

  async findAllByTutor(tutorIdentifier: string): Promise<IPet[]> {
    return this.petRepository.findAllByTutor(tutorIdentifier);
  }

  async findOne(identifier: string, tutorIdentifier: string): Promise<IPet> {
    const pet = await this.petRepository.findById(identifier);
    if (!pet) throw new NotFoundException('Pet não encontrado');
    if (pet.tutor_identifier !== tutorIdentifier) {
      throw new ForbiddenException('Você não tem permissão para acessar este pet');
    }
    return pet;
  }

  async create(dto: ICreatePet, tutorIdentifier: string): Promise<IPet> {
    return this.petRepository.create({
      identifier: createId(),
      name: dto.name,
      species: dto.species,
      size: dto.size,
      age: dto.age ?? null,
      photo_url: null,
      photo_data: null,
      photo_mime_type: null,
      photo_size: null,
      photo_hash: null,
      observations: dto.observations ?? null,
      tutor_identifier: tutorIdentifier,
    });
  }

  async updatePhoto(
    identifier: string,
    fileBuffer: Buffer,
    mimeType: string,
    fileSize: number,
    tutorIdentifier: string,
  ): Promise<IPet> {
    await this.findOne(identifier, tutorIdentifier);

    if (!fileBuffer.length) {
      throw new BadRequestException('Arquivo de imagem inválido');
    }

    const photoHash = createHash('sha256').update(fileBuffer).digest('hex');
    const photoUrl = `/tutors/${tutorIdentifier}/pets/${identifier}/photo`;

    await this.petRepository.update(identifier, {
      photo_url: photoUrl,
      photo_data: fileBuffer,
      photo_mime_type: mimeType,
      photo_size: fileSize,
      photo_hash: photoHash,
    });

    return this.petRepository.findById(identifier) as Promise<IPet>;
  }

  async getPhoto(
    identifier: string,
    tutorIdentifier: string,
  ): Promise<{ data: Buffer; mimeType: string }> {
    const pet = await this.petRepository.findPhotoById(identifier);
    if (!pet) throw new NotFoundException('Pet não encontrado');
    if (pet.tutor_identifier !== tutorIdentifier) {
      throw new ForbiddenException('Você não tem permissão para acessar este pet');
    }
    if (!pet.photo_data || !pet.photo_mime_type) {
      throw new NotFoundException('Foto do pet não encontrada');
    }

    return {
      data: pet.photo_data,
      mimeType: pet.photo_mime_type,
    };
  }

  async update(
    identifier: string,
    dto: IUpdatePet,
    tutorIdentifier: string,
  ): Promise<IPet> {
    await this.findOne(identifier, tutorIdentifier);
    await this.petRepository.update(identifier, dto);
    return this.petRepository.findById(identifier) as Promise<IPet>;
  }

  async remove(identifier: string, tutorIdentifier: string): Promise<void> {
    await this.findOne(identifier, tutorIdentifier);
    await this.petRepository.delete(identifier);
  }
}
