import { IUser } from '../../users/interfaces/user.interface';

export interface ITutor {
  identifier: string;
  user: IUser;
  address: string;
  phone: string;
  photo_url: string | null;
  created_at: Date;
  updated_at: Date;
}
