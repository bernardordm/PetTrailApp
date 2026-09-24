import { IUpdateWalker } from '../interfaces/walker.interface';
import { IsBoolean } from 'class-validator';

export class AvailabilityWalkerDto implements IUpdateWalker {
  @IsBoolean()
  available: boolean;
}
