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

  async findById(identifier: string): Promise<PetEntity | null> {
    return this.repository.findOneBy({ identifier });
  }
}
