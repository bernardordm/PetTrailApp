import { IsNumber, IsString } from 'class-validator';
import { ICreateTour } from '../interfaces/tour.interface';

export class CreateTourDto implements ICreateTour {
  @IsString()
  walker_identifier: string;

  @IsString()
  tutor_identifier: string;

  @IsString()
  pet_identifier: string;

  @IsNumber()
  tutor_latitude: number;

  @IsNumber()
  tutor_longitude: number;
}
