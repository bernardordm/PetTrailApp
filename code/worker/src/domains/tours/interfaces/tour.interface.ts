import { TourStatus } from '../enums/tour-status.enum';

export interface ITour {
  identifier: string;
  status: TourStatus;
  confirmation_code: string | null;
  termination_code: string | null;
  termination_qr_nonce: string | null;
  termination_qr_expires_at: Date | null;
  started_at: Date | null;
  finished_at: Date | null;
  price: number | null;
  total_time_seconds: number | null;
  distance_meters: number | null;
  path: object | null;
  rating: number | null;
  walker_identifier: string;
  tutor_identifier: string;
  pet_identifier: string;
  created_at: Date;
  updated_at: Date;
}

export interface ICreateTour {
  walker_identifier: string;
  tutor_identifier: string;
  pet_identifier: string;
  tutor_latitude: number;
  tutor_longitude: number;
}

export interface IConfirmTour {
  accepted: boolean;
}

export interface IStartTour {
  confirmation_code: string;
}

export interface IGenerateTerminationCode {
  distance_meters: number;
  total_time_seconds: number;
  path: object;
}

export interface IFinishTour {
  termination_code?: string;
  qr_token?: string;
}
