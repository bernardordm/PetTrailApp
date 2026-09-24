export interface IChatMessagePayload {
  identifier: string;
  tour_id: string;
  sender_id: string;
  content: string;
  sent_at: Date;
}

export interface IValidationResult {
  ok: boolean;
  code?: string;
  message?: string;
}
