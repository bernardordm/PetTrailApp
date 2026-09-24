import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PetEntity } from '../entities/pet.entity';

@Injectable()
export class PetRepository {
  constructor(
    @InjectRepository(PetEntity)
    private readonly repository: Repository<PetEntity>,
  ) {}

  async findAllByTutor(tutorIdentifier: string): Promise<PetEntity[]> {
    return this.repository.find({
      where: { tutor_identifier: tutorIdentifier },
      order: { created_at: 'DESC' },
    });
  }

  async findById(identifier: string): Promise<PetEntity | null> {
    return this.repository.findOneBy({ identifier });
  }

  async findPhotoById(identifier: string): Promise<PetEntity | null> {
    return this.repository
      .createQueryBuilder('pet')
      .addSelect([
        'pet.photo_data',
        'pet.photo_mime_type',
        'pet.photo_size',
        'pet.photo_hash',
      ])
      .where('pet.identifier = :identifier', { identifier })
      .getOne();
  }

  async create(data: Partial<PetEntity>): Promise<PetEntity> {
    const pet = this.repository.create(data);
    return this.repository.save(pet);
  }

  async update(identifier: string, data: Partial<PetEntity>): Promise<void> {
    await this.repository.update(identifier, data);
  }

  async delete(identifier: string): Promise<void> {
    await this.repository.delete(identifier);
  }
}
