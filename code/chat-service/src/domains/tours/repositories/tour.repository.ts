import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TourEntity } from '../entities/tour.entity';

@Injectable()
export class TourRepository {
  constructor(
    @InjectRepository(TourEntity)
    private readonly repository: Repository<TourEntity>,
  ) {}

  async findById(identifier: string): Promise<TourEntity | null> {
    return this.repository.findOneBy({ identifier });
  }
}
