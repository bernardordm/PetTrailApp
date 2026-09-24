import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

export interface IWalkerLocationInit {
  name: string;
  available: boolean;
  status: 'idle' | 'pending' | 'on_tour';
}

export interface IWalkerLocationCoords {
  name: string;
  available: boolean;
  status: 'idle' | 'pending' | 'on_tour';
  latitude: number;
  longitude: number;
  updatedAt: number;
}

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private db: admin.database.Database;

  onModuleInit() {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (!serviceAccountJson || !process.env.FIREBASE_DATABASE_URL) {
      this.logger.warn(
        'Firebase credentials not configured – skipping initialization',
      );
      return;
    }

    if (admin.apps.length === 0) {
      const serviceAccount = JSON.parse(
        serviceAccountJson,
      ) as admin.ServiceAccount;
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: process.env.FIREBASE_DATABASE_URL,
      });
    }

    this.db = admin.database();
    this.logger.log('Firebase initialized');
  }

  // Chamado ao ativar disponibilidade — escreve dados estáticos do walker
  async initWalkerLocation(
    identifier: string,
    data: IWalkerLocationInit,
  ): Promise<void> {
    await this.db.ref(`walker_locations/${identifier}`).set(data);
  }

  // Chamado a cada 30s — atualiza apenas coordenadas e timestamp
  async updateWalkerCoords(
    identifier: string,
    data: IWalkerLocationCoords,
  ): Promise<void> {
    await this.db.ref(`walker_locations/${identifier}`).update(data);
  }

  async clearWalkerLocation(identifier: string): Promise<void> {
    await this.db.ref(`walker_locations/${identifier}`).remove();
  }

  async updateWalkerStatus(
    identifier: string,
    status: 'idle' | 'pending' | 'on_tour',
  ): Promise<void> {
    await this.db.ref(`walker_locations/${identifier}`).update({ status });
  }

  async clearWalkerTourNotification(walkerIdentifier: string): Promise<void> {
    await this.db
      .ref(`notifications/walkers/${walkerIdentifier}/pending_tour`)
      .remove();
  }

  async notifyWalkerNewTour(
    walkerIdentifier: string,
    data: {
      tour_identifier: string;
      tutor_name: string;
      pet_name: string;
      created_at: string;
    },
  ): Promise<void> {
    await this.db
      .ref(`notifications/walkers/${walkerIdentifier}/pending_tour`)
      .set(data);
  }

  async notifyTutorTourResponse(
    tutorIdentifier: string,
    data: {
      tour_identifier: string;
      walker_name: string;
      accepted: boolean;
      status: string;
      confirmation_code?: string;
    },
  ): Promise<void> {
    await this.db
      .ref(`notifications/tutors/${tutorIdentifier}/tour_response`)
      .set(data);
  }

  async clearTutorTourNotification(tutorIdentifier: string): Promise<void> {
    await this.db
      .ref(`notifications/tutors/${tutorIdentifier}/tour_response`)
      .remove();
  }

  async setTutorLocation(
    tutorIdentifier: string,
    data: { latitude: number; longitude: number },
  ): Promise<void> {
    await this.db.ref(`tutor_locations/${tutorIdentifier}`).set(data);
  }

  async clearTutorLocation(tutorIdentifier: string): Promise<void> {
    await this.db.ref(`tutor_locations/${tutorIdentifier}`).remove();
  }

  async setActiveTour(
    tourIdentifier: string,
    data: {
      walker_id: string;
      walker_name: string;
      tutor_id: string;
      tutor_name: string;
    },
  ): Promise<void> {
    await this.db.ref(`active_tours/${tourIdentifier}`).set(data);
  }

  async updateActiveTourStatus(
    tourIdentifier: string,
    data: {
      status: string;
      started_at: string;
    },
  ): Promise<void> {
    await this.db.ref(`active_tours/${tourIdentifier}`).update(data);
  }

  async clearActiveTour(tourIdentifier: string): Promise<void> {
    await this.db.ref(`active_tours/${tourIdentifier}`).remove();
  }

  async notifyWalkerTerminationCode(
    walkerIdentifier: string,
    data: { qr_token: string; tour_identifier: string },
  ): Promise<void> {
    await this.db
      .ref(`notifications/walkers/${walkerIdentifier}/termination_code`)
      .set(data);
  }

  async notifyTutorFinishRequest(
    tutorIdentifier: string,
    data: { tour_identifier: string; walker_name: string },
  ): Promise<void> {
    await this.db
      .ref(`notifications/tutors/${tutorIdentifier}/finish_request`)
      .set(data);
  }

  async clearTerminationNotifications(
    walkerIdentifier: string,
    tutorIdentifier: string,
  ): Promise<void> {
    await Promise.all([
      this.db
        .ref(`notifications/walkers/${walkerIdentifier}/termination_code`)
        .remove(),
      this.db
        .ref(`notifications/tutors/${tutorIdentifier}/finish_request`)
        .remove(),
    ]);
  }

  async clearWalkPath(tourIdentifier: string): Promise<void> {
    await this.db.ref(`walk_paths/${tourIdentifier}`).remove();
  }
}
