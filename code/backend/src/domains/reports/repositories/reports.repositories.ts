import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TourEntity } from '../../tours/entities/tour.entity';
import { TourStatus } from '../../tours/enums/tour-status.enum';

export interface RawReportMetrics {
  total_tours: string;
  finished_tours: string;
  total_earnings: string | null;
  total_distance_meters: string | null;
  total_time_seconds: string | null;
  avg_time_seconds: string | null;
  avg_distance_meters: string | null;
  avg_rating: string | null;
}

export interface RawTourExportRow {
  pet_name: string;
  tutor_name: string;
  started_at: string | null;
  finished_at: string | null;
  distance_meters: string | null;
  total_time_seconds: string | null;
  price: string | null;
  status: string;
}

@Injectable()
export class ReportsRepository {
  constructor(
    @InjectRepository(TourEntity)
    private readonly repository: Repository<TourEntity>,
  ) {}

  async getWalkerMetrics(
    walkerIdentifier: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<RawReportMetrics> {
    const finished = TourStatus.FINISHED;

    const qb = this.repository
      .createQueryBuilder('tour')
      .select('COUNT(*)', 'total_tours')
      .addSelect(
        `COUNT(CASE WHEN tour.status = '${finished}' THEN 1 END)`,
        'finished_tours',
      )
      .addSelect(
        `SUM(CASE WHEN tour.status = '${finished}' THEN tour.price ELSE 0 END)`,
        'total_earnings',
      )
      .addSelect(
        `SUM(CASE WHEN tour.status = '${finished}' THEN tour.distance_meters ELSE 0 END)`,
        'total_distance_meters',
      )
      .addSelect(
        `SUM(CASE WHEN tour.status = '${finished}' THEN tour.total_time_seconds ELSE 0 END)`,
        'total_time_seconds',
      )
      .addSelect(
        `AVG(CASE WHEN tour.status = '${finished}' THEN tour.total_time_seconds END)`,
        'avg_time_seconds',
      )
      .addSelect(
        `AVG(CASE WHEN tour.status = '${finished}' THEN tour.distance_meters END)`,
        'avg_distance_meters',
      )
      .addSelect(
        `AVG(CASE WHEN tour.status = '${finished}' AND tour.rating IS NOT NULL THEN tour.rating END)`,
        'avg_rating',
      )
      .where('tour.walker_identifier = :walkerIdentifier', {
        walkerIdentifier,
      });

    if (startDate) {
      qb.andWhere('tour.created_at >= :startDate', { startDate });
    }
    if (endDate) {
      qb.andWhere('tour.created_at <= :endDate', { endDate });
    }

    return (await qb.getRawOne<RawReportMetrics>()) as RawReportMetrics;
  }

  async getWalkerToursForExport(
    walkerIdentifier: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<RawTourExportRow[]> {
    const qb = this.repository
      .createQueryBuilder('tour')
      .select('pet.name', 'pet_name')
      .addSelect('tutor_user.name', 'tutor_name')
      .addSelect('tour.started_at', 'started_at')
      .addSelect('tour.finished_at', 'finished_at')
      .addSelect('tour.distance_meters', 'distance_meters')
      .addSelect('tour.total_time_seconds', 'total_time_seconds')
      .addSelect('tour.price', 'price')
      .addSelect('tour.status', 'status')
      .innerJoin('pets', 'pet', 'pet.identifier = tour.pet_identifier')
      .innerJoin(
        'users',
        'tutor_user',
        'tutor_user.identifier = tour.tutor_identifier',
      )
      .where('tour.walker_identifier = :walkerIdentifier', { walkerIdentifier })
      .orderBy('tour.created_at', 'DESC');

    if (startDate) {
      qb.andWhere('tour.created_at >= :startDate', { startDate });
    }
    if (endDate) {
      qb.andWhere('tour.created_at <= :endDate', { endDate });
    }

    return qb.getRawMany<RawTourExportRow>();
  }
}
