import { UserRole } from '../../users/interfaces/user.interface';

export interface IJwtPayload {
  sub: string;
  role: UserRole;
}

export interface IAuthLogin {
  identifier: string;
  name: string;
  email: string;
  role: UserRole;
  accessToken: string;
}

export interface IAuthenticatedUser {
  identifier: string;
  role: UserRole;
}
