import { IsOptional, IsString } from 'class-validator';
import { ICreatePet } from '../interfaces/pet.interface';

export class CreatePetDto implements ICreatePet {
  @IsString()
  name: string;

  @IsString()
  species: string;

  @IsString()
  size: string;

  @IsOptional()
  @IsString()
  age?: string;

  @IsOptional()
  @IsString()
  observations?: string;
}
