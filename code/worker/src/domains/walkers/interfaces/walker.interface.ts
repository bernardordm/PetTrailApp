import { IUser } from '../../users/interfaces/user.interface';

export interface IWalker {
  identifier: string;
  user: IUser;
  phone: string;
  photo_url: string | null;
  document: string;
  walkPrice: number;
  averageRideTime: number;
  available: boolean;
  status: 'idle' | 'pending' | 'on_tour';
  averageRating: number | null;
  created_at: Date;
  updated_at: Date;
}
