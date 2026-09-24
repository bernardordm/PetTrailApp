import { Pet } from "./pets.interface"
import { TutorProfile } from "./tutors.interface"
import { WalkerProfile } from "./walkers.interface"

export enum TourStatus {
  WAITING_ACCEPTANCE = "WAITING_ACCEPTANCE",
  WALKER_ON_THE_WAY = "WALKER_ON_THE_WAY",
  IN_PROGRESS = "IN_PROGRESS",
  FINISHED = "FINISHED",
  REFUSED = "REFUSED",
}

export interface Tour {
  identifier: string
  status: TourStatus
  confirmation_code: string | null
  started_at: string | null
  finished_at: string | null
  walker_identifier: string
  walker: WalkerProfile
  tutor_identifier: string
  tutor: TutorProfile
  pet_identifier: string
  pet: Pet
  price: number | null
  total_time_seconds: number | null
  distance_meters: number | null
  path: Record<string, { lat: number; lng: number }> | null
  rating: number | null
  created_at: string
  updated_at: string
}
