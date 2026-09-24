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

  async findById(identifier: string): Promise<TutorEntity | null> {
    return this.repository
      .createQueryBuilder('tutor')
      .leftJoin('tutor.user', 'user')
      .select('tutor')
      .addSelect(['user.identifier', 'user.name', 'user.email', 'user.role'])
      .where('tutor.identifier = :identifier', { identifier })
      .getOne();
  }
}
