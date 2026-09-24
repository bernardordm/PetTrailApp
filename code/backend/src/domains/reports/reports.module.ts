import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TourEntity } from '../tours/entities/tour.entity';
import { ReportsRepository } from './repositories/reports.repositories';
import { ReportsService } from './services/reports.service';
import { ReportsController } from './controllers/reports.controller';

@Module({
  imports: [TypeOrmModule.forFeature([TourEntity])],
  controllers: [ReportsController],
  providers: [ReportsRepository, ReportsService],
})
export class ReportsModule {}
