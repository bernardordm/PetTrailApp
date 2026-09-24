import { IsString, MinLength } from 'class-validator';

export class SendMessageDto {
  @IsString()
  tour_id: string;

  @IsString()
  @MinLength(1)
  content: string;

  @IsString()
  client_temp_id: string;
}
