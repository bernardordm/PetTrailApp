import { UserRole } from '../../users/interfaces/user.interface';

export interface IJwtPayload {
  sub: string;
  role: UserRole;
}

export interface IAuthenticatedUser {
  identifier: string;
  role: UserRole;
}
