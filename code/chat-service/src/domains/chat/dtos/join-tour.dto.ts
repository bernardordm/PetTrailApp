import { IsOptional, IsString } from 'class-validator';

export class JoinTourDto {
  @IsString()
  tour_id: string;

  @IsOptional()
  @IsString()
  last_received_id?: string;
}
