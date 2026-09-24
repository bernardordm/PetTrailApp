import { IsEmail, IsEnum, IsString, MinLength } from 'class-validator';
import { ICreateUser, UserRole } from '../interfaces/user.interface';

export class CreateUserDto implements ICreateUser {
  @IsString()
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsEnum(UserRole)
  role: UserRole;
}
