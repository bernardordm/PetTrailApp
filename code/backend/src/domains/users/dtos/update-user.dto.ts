import { IsOptional, IsString, MinLength } from 'class-validator';
import { IUpdateUser } from '../interfaces/user.interface';

export class UpdateUserDto implements IUpdateUser {
  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;
}
