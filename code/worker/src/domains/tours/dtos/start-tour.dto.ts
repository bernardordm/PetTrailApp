import { IsString, Length } from 'class-validator';

export class StartTourDto {
  @IsString()
  @Length(4, 4)
  confirmation_code: string;
}
