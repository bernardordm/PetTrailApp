import { IsDateString, IsEnum, IsOptional } from 'class-validator';

export class GetReportsQueryDto {
  @IsOptional()
  @IsEnum(['week', 'month'])
  period?: 'week' | 'month';

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}
