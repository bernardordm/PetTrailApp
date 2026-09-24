import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TutorEntity } from './entities/tutor.entity';
import { TutorRepository } from './repositories/tutor.repository';
import { TutorsService } from './services/tutors.service';
import { TutorsController } from './controllers/tutors.controller';

@Module({
  imports: [TypeOrmModule.forFeature([TutorEntity])],
  controllers: [TutorsController],
  providers: [TutorRepository, TutorsService],
  exports: [TutorRepository, TutorsService],
})
export class TutorsModule {}
