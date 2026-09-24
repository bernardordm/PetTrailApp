import { IsOptional, IsString } from 'class-validator';
import { IUpdateTutor } from '../interfaces/tutor.interface';

export class UpdateTutorDto implements IUpdateTutor {
  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  phone?: string;


}
