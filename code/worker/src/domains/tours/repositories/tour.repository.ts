import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TourEntity } from '../entities/tour.entity';
import { UserRole } from '../../users/interfaces/user.interface';
import { TourStatus } from '../enums/tour-status.enum';

@Injectable()
export class TourRepository {
  constructor(
    @InjectRepository(TourEntity)
    private readonly repository: Repository<TourEntity>,
  ) {}

  async create(data: Partial<TourEntity>): Promise<TourEntity> {
    const tour = this.repository.create(data);
    return this.repository.save(tour);
  }

  async findById(identifier: string): Promise<TourEntity | null> {
    return this.repository.findOneBy({ identifier });
  }

  async findByIdWithRelations(identifier: string): Promise<TourEntity | null> {
    return this.repository.findOne({
      where: { identifier },
      relations: ['walker', 'walker.user', 'tutor', 'tutor.user', 'pet'],
    });
  }

  async findByUser(
    userIdentifier: string,
    role: UserRole,
  ): Promise<TourEntity[]> {
    const where =
      role === UserRole.TUTOR
        ? { tutor_identifier: userIdentifier }
        : { walker_identifier: userIdentifier };

    return this.repository.find({
      where,
      relations: ['walker', 'walker.user', 'tutor', 'tutor.user', 'pet'],
      order: { created_at: 'DESC' },
    });
  }

  async findLastCompletedByUser(
    userIdentifier: string,
    role: UserRole,
  ): Promise<TourEntity | null> {
    const qb = this.repository
      .createQueryBuilder('tour')
      .leftJoinAndSelect('tour.walker', 'walker')
      .leftJoinAndSelect('walker.user', 'walkerUser')
      .leftJoinAndSelect('tour.tutor', 'tutor')
      .leftJoinAndSelect('tutor.user', 'tutorUser')
      .leftJoinAndSelect('tour.pet', 'pet')
      .where('tour.status = :status', { status: TourStatus.FINISHED });

    if (role === UserRole.TUTOR) {
      qb.andWhere('tour.tutor_identifier = :id', { id: userIdentifier });
    } else {
      qb.andWhere('tour.walker_identifier = :id', { id: userIdentifier });
    }

    return qb.orderBy('tour.finished_at', 'DESC').getOne();
  }

  async update(identifier: string, data: Partial<TourEntity>): Promise<void> {
    await this.repository.update(identifier, data);
  }

  async getAverageRatingForWalker(
    walkerIdentifier: string,
  ): Promise<number | null> {
    const result = await this.repository
      .createQueryBuilder('tour')
      .select('AVG(tour.rating)', 'average')
      .where('tour.walker_identifier = :walkerIdentifier', { walkerIdentifier })
      .andWhere('tour.rating IS NOT NULL')
      .getRawOne<{ average: string | null }>();

    return result?.average ? Number(Number(result.average).toFixed(2)) : null;
  }
}
