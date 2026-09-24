import { IsBoolean } from 'class-validator';
import { IConfirmTour } from '../interfaces/tour.interface';

export class ConfirmTourDto implements IConfirmTour {
  @IsBoolean()
  accepted: boolean;
}
