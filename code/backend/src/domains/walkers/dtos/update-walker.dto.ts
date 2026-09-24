import { IsBoolean, IsNumber, IsOptional, IsString } from 'class-validator';
import { IUpdateWalker } from '../interfaces/walker.interface';

export class UpdateWalkerDto implements IUpdateWalker {
  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  document?: string;

  @IsOptional()
  @IsNumber()
  walkPrice?: number;

  @IsOptional()
  @IsNumber()
  averageRideTime?: number;

  @IsOptional()
  @IsBoolean()
  available?: boolean;
}
