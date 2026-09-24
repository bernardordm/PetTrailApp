import { IsNumber, IsObject, Min } from 'class-validator';

export class GenerateTerminationCodeDto {
  @IsNumber()
  @Min(0)
  distance_meters: number;

  @IsNumber()
  @Min(0)
  total_time_seconds: number;

  @IsObject()
  path: object;
}
