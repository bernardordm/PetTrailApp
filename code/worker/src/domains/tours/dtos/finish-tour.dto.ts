import { IsOptional, IsString, Length } from 'class-validator';

export class FinishTourDto {
  @IsOptional()
  @IsString()
  @Length(4, 4)
  termination_code?: string;

  @IsOptional()
  @IsString()
  qr_token?: string;
}
