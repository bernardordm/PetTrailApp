import { Module } from '@nestjs/common';
import { ToursService } from './services/tours.service';
import { ToursController } from './controllers/tours.controller';
import { TourPublisher } from './publishers/tour.publisher';
import { WalkerModule } from '../walkers/walker.module';
import { TutorsModule } from '../tutors/tutors.module';
import { PetsModule } from '../pets/pets.module';

@Module({
  imports: [WalkerModule, TutorsModule, PetsModule],
  controllers: [ToursController],
  providers: [ToursService, TourPublisher],
})
export class ToursModule {}
