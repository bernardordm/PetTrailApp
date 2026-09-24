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

export interface ICreateUser {
  name: string;
  email: string;
  password: string;
  role: UserRole;
}

export interface IUpdateUser {
  password?: string;
}
