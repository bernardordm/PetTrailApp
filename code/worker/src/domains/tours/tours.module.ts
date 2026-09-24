import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TourEntity } from './entities/tour.entity';
import { TourRepository } from './repositories/tour.repository';
import { ToursService } from './services/tours.service';
import { ToursController } from './controllers/tours.controller';
import { WalkerModule } from '../walkers/walker.module';
import { TutorsModule } from '../tutors/tutors.module';
import { PetsModule } from '../pets/pets.module';
import { FirebaseModule } from '../../app/firebase/firebase.module';
import { TourRequestConsumer } from '../../queue/tour-request.consumer';
import { EmailModule } from '../../app/email/email.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([TourEntity]),
    WalkerModule,
    TutorsModule,
    PetsModule,
    FirebaseModule,
    EmailModule,
  ],
  controllers: [ToursController],
  providers: [TourRepository, ToursService, TourRequestConsumer],
})
export class ToursModule {}
