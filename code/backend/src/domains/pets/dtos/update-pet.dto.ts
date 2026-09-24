import { IsOptional, IsString } from 'class-validator';
import { IUpdatePet } from '../interfaces/pet.interface';

export class UpdatePetDto implements IUpdatePet {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  species?: string;

  @IsOptional()
  @IsString()
  size?: string;

  @IsOptional()
  @IsString()
  age?: string;

  @IsOptional()
  @IsString()
  observations?: string;
}
