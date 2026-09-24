import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TutorEntity } from './entities/tutor.entity';
import { TutorRepository } from './repositories/tutor.repository';

@Module({
  imports: [TypeOrmModule.forFeature([TutorEntity])],
  providers: [TutorRepository],
  exports: [TutorRepository],
})
export class TutorsModule {}
