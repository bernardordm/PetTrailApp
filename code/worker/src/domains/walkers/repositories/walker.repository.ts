import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WalkerEntity } from '../entities/walker.entity';

@Injectable()
export class WalkerRepository {
  constructor(
    @InjectRepository(WalkerEntity)
    private readonly repository: Repository<WalkerEntity>,
  ) {}

  async findById(identifier: string): Promise<WalkerEntity | null> {
    return this.repository
      .createQueryBuilder('walker')
      .leftJoin('walker.user', 'user')
      .select('walker')
      .addSelect(['user.identifier', 'user.name', 'user.email', 'user.role'])
      .where('walker.identifier = :identifier', { identifier })
      .getOne();
  }

  async update(identifier: string, data: Partial<WalkerEntity>): Promise<void> {
    await this.repository.update(identifier, data);
  }
}
