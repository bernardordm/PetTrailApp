import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PetEntity } from './entities/pet.entity';
import { PetRepository } from './repositories/pet.repository';

@Module({
  imports: [TypeOrmModule.forFeature([PetEntity])],
  providers: [PetRepository],
  exports: [PetRepository],
})
export class PetsModule {}
