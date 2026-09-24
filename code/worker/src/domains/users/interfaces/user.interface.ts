export enum UserRole {
  TUTOR = 'tutor',
  WALKER = 'walker',
}

export interface IUser {
  identifier: string;
  name: string;
  email: string;
  role: UserRole;
}

export interface IUserWithPassword extends IUser {
  password: string;
}
