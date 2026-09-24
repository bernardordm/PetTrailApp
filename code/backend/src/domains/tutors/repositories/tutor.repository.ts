import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TutorEntity } from '../entities/tutor.entity';

@Injectable()
export class TutorRepository {
  constructor(
    @InjectRepository(TutorEntity)
    private readonly repository: Repository<TutorEntity>,
  ) {}

  async findAll(): Promise<TutorEntity[]> {
    return this.repository.find({ relations: ['user'] });
  }

  async findById(identifier: string): Promise<TutorEntity | null> {
    return this.repository
      .createQueryBuilder('tutor')
      .leftJoin('tutor.user', 'user')
      .select('tutor')
      .addSelect(['user.identifier', 'user.name', 'user.email', 'user.role'])
      .where('tutor.identifier = :identifier', { identifier })
      .getOne();
  }

  async findPhotoById(identifier: string): Promise<TutorEntity | null> {
    return this.repository
      .createQueryBuilder('tutor')
      .addSelect([
        'tutor.photo_data',
        'tutor.photo_mime_type',
        'tutor.photo_size',
        'tutor.photo_hash',
      ])
      .where('tutor.identifier = :identifier', { identifier })
      .getOne();
  }

  async update(identifier: string, data: Partial<TutorEntity>): Promise<void> {
    await this.repository.update(identifier, data);
  }
}
