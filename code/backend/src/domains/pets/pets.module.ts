import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PetEntity } from './entities/pet.entity';
import { PetRepository } from './repositories/pet.repository';
import { PetsService } from './services/pets.service';
import { PetsController } from './controllers/pets.controller';

@Module({
  imports: [TypeOrmModule.forFeature([PetEntity])],
  controllers: [PetsController],
  providers: [PetRepository, PetsService],
  exports: [PetRepository, PetsService],
})
export class PetsModule {}
