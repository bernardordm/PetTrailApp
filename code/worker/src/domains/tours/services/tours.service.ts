import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { createHmac, randomUUID, timingSafeEqual } from 'crypto';
import { TourRepository } from '../repositories/tour.repository';
import { WalkerRepository } from '../../walkers/repositories/walker.repository';
import { TutorRepository } from '../../tutors/repositories/tutor.repository';
import { PetRepository } from '../../pets/repositories/pet.repository';
import { FirebaseService } from '../../../app/firebase/firebase.service';
import { EmailService } from '../../../app/email/email.service';
import {
  ICreateTour,
  IConfirmTour,
  IStartTour,
  IGenerateTerminationCode,
  IFinishTour,
  ITour,
} from '../interfaces/tour.interface';
import { ITutor } from '../../tutors/interfaces/tutor.interface';
import { IWalker } from '../../walkers/interfaces/walker.interface';

import { IAuthenticatedUser } from '../../auth/interfaces/auth.interface';
import { UserRole } from '../../users/interfaces/user.interface';
import { TourStatus } from '../enums/tour-status.enum';

@Injectable()
export class ToursService {
  private readonly logger = new Logger(ToursService.name);

  constructor(
    private readonly tourRepository: TourRepository,
    private readonly walkerRepository: WalkerRepository,
    private readonly tutorRepository: TutorRepository,
    private readonly petRepository: PetRepository,
    private readonly firebaseService: FirebaseService,
    private readonly emailService: EmailService,
  ) {}

  async createTour(dto: ICreateTour): Promise<ITour> {
    const walker = await this.walkerRepository.findById(dto.walker_identifier);
    if (!walker) throw new NotFoundException('Passeador não encontrado');

    const tutor = await this.tutorRepository.findById(dto.tutor_identifier);
    if (!tutor) throw new NotFoundException('Tutor não encontrado');

    const pet = await this.petRepository.findById(dto.pet_identifier);
    if (!pet) throw new NotFoundException('Pet não encontrado');

    await this.walkerRepository.update(dto.walker_identifier, {
      status: 'pending',
    });

    const tour = await this.tourRepository.create({
      identifier: createId(),
      status: TourStatus.WAITING_ACCEPTANCE,
      confirmation_code: null,
      started_at: null,
      finished_at: null,
      price: walker.walkPrice ?? null,
      walker_identifier: dto.walker_identifier,
      tutor_identifier: dto.tutor_identifier,
      pet_identifier: dto.pet_identifier,
    });

    await this.firebaseService.updateWalkerStatus(
      dto.walker_identifier,
      'pending',
    );
    await this.firebaseService.setTutorLocation(dto.tutor_identifier, {
      latitude: dto.tutor_latitude,
      longitude: dto.tutor_longitude,
    });
    await this.firebaseService.notifyWalkerNewTour(dto.walker_identifier, {
      tour_identifier: tour.identifier,
      tutor_name: (tutor as ITutor).user.name,
      pet_name: pet.name,
      created_at: tour.created_at.toISOString(),
    });

    await this.firebaseService.notifyTutorTourCreated(dto.tutor_identifier, {
      tour_id: tour.identifier,
      walker_name: (walker as IWalker).user.name,
      pet_name: pet.name,
    });

    return tour;
  }

  async confirmRequest(
    tourIdentifier: string,
    dto: IConfirmTour,
  ): Promise<ITour> {
    const tour = await this.tourRepository.findById(tourIdentifier);
    if (!tour) throw new NotFoundException('Passeio não encontrado');

    const walker = await this.walkerRepository.findById(tour.walker_identifier);
    const tutor = await this.tutorRepository.findById(tour.tutor_identifier);

    const newStatus = dto.accepted
      ? TourStatus.WALKER_ON_THE_WAY
      : TourStatus.REFUSED;

    const confirmationCode = dto.accepted ? this.generateCode() : null;

    await this.tourRepository.update(tourIdentifier, {
      status: newStatus,
      ...(confirmationCode ? { confirmation_code: confirmationCode } : {}),
    });

    if (dto.accepted) {
      await this.firebaseService.setActiveTour(tourIdentifier, {
        walker_id: tour.walker_identifier,
        walker_name: (walker as IWalker).user.name,
        tutor_id: tour.tutor_identifier,
        tutor_name: (tutor as ITutor).user.name,
      });
    } else {
      await this.walkerRepository.update(tour.walker_identifier, {
        status: 'idle',
      });
      await this.firebaseService.updateWalkerStatus(
        tour.walker_identifier,
        'idle',
      );
      await this.firebaseService.clearTutorLocation(tour.tutor_identifier);
    }

    await this.firebaseService.clearWalkerTourNotification(
      tour.walker_identifier,
    );
    await this.firebaseService.clearTutorTourCreatedNotification(
      tour.tutor_identifier,
    );
    await this.firebaseService.notifyTutorTourResponse(tour.tutor_identifier, {
      tour_identifier: tour.identifier,
      walker_name: (walker as IWalker).user.name,
      accepted: dto.accepted,
      status: newStatus,
      ...(confirmationCode ? { confirmation_code: confirmationCode } : {}),
    });

    return (await this.tourRepository.findById(
      tourIdentifier,
    )) as unknown as Promise<ITour>;
  }

  async startRequest(
    tourIdentifier: string,
    dto: IStartTour,
    user: IAuthenticatedUser,
  ): Promise<ITour> {
    const tour = await this.tourRepository.findById(tourIdentifier);
    if (!tour) throw new NotFoundException('Passeio não encontrado');

    if (
      user.role !== UserRole.WALKER ||
      tour.walker_identifier !== user.identifier
    ) {
      throw new ForbiddenException(
        'Você não tem permissão para iniciar este passeio',
      );
    }

    if (tour.status !== TourStatus.WALKER_ON_THE_WAY) {
      throw new BadRequestException(
        'Passeio não está pronto para iniciar. Aguarde o tutor responder.',
      );
    }

    if (!tour.confirmation_code) {
      throw new BadRequestException(
        'Código de confirmação indisponível para iniciar o passeio',
      );
    }

    if (dto.confirmation_code !== tour.confirmation_code) {
      throw new BadRequestException('Código de confirmação incorreto');
    }

    const startedAt = new Date();

    await this.tourRepository.update(tourIdentifier, {
      status: TourStatus.IN_PROGRESS,
      started_at: startedAt,
    });

    await this.walkerRepository.update(tour.walker_identifier, {
      status: 'on_tour',
    });

    await this.firebaseService.updateActiveTourStatus(tourIdentifier, {
      status: TourStatus.IN_PROGRESS,
      started_at: startedAt.toISOString(),
    });

    await this.firebaseService.updateWalkerStatus(
      tour.walker_identifier,
      'on_tour',
    );

    return (await this.tourRepository.findById(
      tourIdentifier,
    )) as unknown as Promise<ITour>;
  }

  async generateTerminationCode(
    tourIdentifier: string,
    dto: IGenerateTerminationCode,
    user: IAuthenticatedUser,
  ): Promise<{ qr_token: string; expires_at: string }> {
    const tour = await this.tourRepository.findById(tourIdentifier);
    if (!tour) throw new NotFoundException('Passeio não encontrado');

    if (
      user.role !== UserRole.WALKER ||
      tour.walker_identifier !== user.identifier
    ) {
      throw new ForbiddenException(
        'Você não tem permissão para encerrar este passeio',
      );
    }

    if (tour.status !== TourStatus.IN_PROGRESS) {
      throw new BadRequestException('O passeio não está em andamento');
    }

    const walker = await this.walkerRepository.findById(tour.walker_identifier);
    if (!walker) throw new NotFoundException('Passeador não encontrado');

    const { token, nonce, expiresAt } = this.generateTerminationQrToken({
      tourIdentifier,
      walkerIdentifier: tour.walker_identifier,
      tutorIdentifier: tour.tutor_identifier,
    });

    await this.tourRepository.update(tourIdentifier, {
      termination_code: null,
      termination_qr_nonce: nonce,
      termination_qr_expires_at: expiresAt,
      distance_meters: dto.distance_meters,
      total_time_seconds: dto.total_time_seconds,
      path: dto.path,
    });

    await this.firebaseService.notifyWalkerTerminationCode(
      tour.walker_identifier,
      { qr_token: token, tour_identifier: tourIdentifier },
    );

    await this.firebaseService.notifyTutorFinishRequest(tour.tutor_identifier, {
      tour_identifier: tourIdentifier,
      walker_name: walker.user.name,
    });

    return { qr_token: token, expires_at: expiresAt.toISOString() };
  }

  async finishTour(
    tourIdentifier: string,
    dto: IFinishTour,
    user: IAuthenticatedUser,
  ): Promise<ITour> {
    const tour = await this.tourRepository.findById(tourIdentifier);
    if (!tour) throw new NotFoundException('Passeio não encontrado');

    if (
      user.role !== UserRole.TUTOR ||
      tour.tutor_identifier !== user.identifier
    ) {
      throw new ForbiddenException(
        'Você não tem permissão para finalizar este passeio',
      );
    }

    if (tour.status !== TourStatus.IN_PROGRESS) {
      throw new BadRequestException('O passeio não está em andamento');
    }

    const hasQrToken = Boolean(dto.qr_token);
    const hasLegacyCode = Boolean(dto.termination_code);
    if (!hasQrToken && !hasLegacyCode) {
      throw new BadRequestException(
        'Envie um QR válido para finalizar o passeio',
      );
    }

    if (hasQrToken) {
      this.assertTerminationQrToken({
        token: dto.qr_token as string,
        tourIdentifier: tour.identifier,
        walkerIdentifier: tour.walker_identifier,
        tutorIdentifier: tour.tutor_identifier,
        expectedNonce: tour.termination_qr_nonce,
        expiresAt: tour.termination_qr_expires_at,
      });
    } else {
      if (!tour.termination_code) {
        throw new BadRequestException(
          'Código de encerramento ainda não foi gerado',
        );
      }
      if (dto.termination_code !== tour.termination_code) {
        throw new BadRequestException('Código de encerramento incorreto');
      }
    }

    const finishedAt = new Date();

    await this.tourRepository.update(tourIdentifier, {
      status: TourStatus.FINISHED,
      finished_at: finishedAt,
      termination_qr_nonce: null,
      termination_qr_expires_at: null,
    });

    await this.walkerRepository.update(tour.walker_identifier, {
      status: 'idle',
    });

    await Promise.all([
      this.firebaseService.updateWalkerStatus(tour.walker_identifier, 'idle'),
      this.firebaseService.clearActiveTour(tourIdentifier),
      this.firebaseService.clearWalkPath(tourIdentifier),
      this.firebaseService.clearTerminationNotifications(
        tour.walker_identifier,
        tour.tutor_identifier,
      ),
      this.firebaseService.clearTutorLocation(tour.tutor_identifier),
    ]);

    const finishedTour = (await this.tourRepository.findById(
      tourIdentifier,
    )) as unknown as ITour;

    void this.dispatchTourSummaryEmail(tour.tutor_identifier, tour.walker_identifier, tour.pet_identifier, finishedTour);

    return finishedTour;
  }

  async rateTour(
    tourIdentifier: string,
    rating: number,
    user: IAuthenticatedUser,
  ): Promise<ITour> {
    const tour = await this.tourRepository.findById(tourIdentifier);
    if (!tour) throw new NotFoundException('Passeio não encontrado');

    if (tour.status !== TourStatus.FINISHED)
      throw new BadRequestException(
        'Só é possível avaliar passeios finalizados',
      );

    if (
      user.role !== UserRole.TUTOR ||
      tour.tutor_identifier !== user.identifier
    )
      throw new ForbiddenException('Você não pode avaliar este passeio');

    if (tour.rating !== null)
      throw new BadRequestException('Este passeio já foi avaliado');

    await this.tourRepository.update(tourIdentifier, { rating });

    const average = await this.tourRepository.getAverageRatingForWalker(
      tour.walker_identifier,
    );
    await this.walkerRepository.update(tour.walker_identifier, {
      averageRating: average,
    });

    return (await this.tourRepository.findById(
      tourIdentifier,
    )) as unknown as ITour;
  }

  async getMyTours(currentUser: IAuthenticatedUser): Promise<ITour[]> {
    return this.tourRepository.findByUser(
      currentUser.identifier,
      currentUser.role,
    );
  }

  async getMyLastCompletedTour(
    currentUser: IAuthenticatedUser,
  ): Promise<ITour | null> {
    return this.tourRepository.findLastCompletedByUser(
      currentUser.identifier,
      currentUser.role,
    );
  }

  async getTourById(
    identifier: string,
    currentUser: IAuthenticatedUser,
  ): Promise<ITour> {
    const tour = await this.tourRepository.findByIdWithRelations(identifier);
    if (!tour) throw new NotFoundException('Passeio não encontrado');

    const isTutor = tour.tutor_identifier === currentUser.identifier;
    const isWalker = tour.walker_identifier === currentUser.identifier;
    if (!isTutor && !isWalker) {
      throw new ForbiddenException('Acesso negado');
    }

    return tour;
  }

  async syncActiveTour(
    tourIdentifier: string,
    currentUser: IAuthenticatedUser,
  ): Promise<void> {
    const tour = await this.tourRepository.findById(tourIdentifier);
    if (!tour) throw new NotFoundException('Passeio não encontrado');

    const isTutor = tour.tutor_identifier === currentUser.identifier;
    const isWalker = tour.walker_identifier === currentUser.identifier;
    if (!isTutor && !isWalker) {
      throw new ForbiddenException('Acesso negado');
    }

    if (
      tour.status !== TourStatus.WALKER_ON_THE_WAY &&
      tour.status !== TourStatus.IN_PROGRESS
    ) {
      throw new BadRequestException('Passeio não está ativo');
    }

    const walker = await this.walkerRepository.findById(tour.walker_identifier);
    const tutor = await this.tutorRepository.findById(tour.tutor_identifier);
    if (!walker || !tutor) {
      throw new NotFoundException('Participantes do passeio não encontrados');
    }

    await this.firebaseService.setActiveTour(tourIdentifier, {
      walker_id: tour.walker_identifier,
      walker_name: (walker as IWalker).user.name,
      tutor_id: tour.tutor_identifier,
      tutor_name: (tutor as ITutor).user.name,
    });

    if (tour.status === TourStatus.IN_PROGRESS) {
      await this.firebaseService.updateActiveTourStatus(tourIdentifier, {
        status: TourStatus.IN_PROGRESS,
        started_at: (tour.started_at ?? new Date()).toISOString(),
      });
    }
  }

  private async dispatchTourSummaryEmail(
    tutorIdentifier: string,
    walkerIdentifier: string,
    petIdentifier: string,
    tour: ITour,
  ): Promise<void> {
    try {
      const [tutor, walker, pet] = await Promise.all([
        this.tutorRepository.findById(tutorIdentifier),
        this.walkerRepository.findById(walkerIdentifier),
        this.petRepository.findById(petIdentifier),
      ]);

      if (!tutor?.user?.email) {
        this.logger.warn(`Email do tutor ${tutorIdentifier} não encontrado, email de resumo não enviado`);
        return;
      }

      await this.emailService.sendTourSummary({
        tutorEmail: tutor.user.email,
        tutorName: tutor.user.name,
        petName: pet?.name ?? 'Pet',
        walkerName: walker?.user?.name ?? 'Passeador',
        startedAt: tour.started_at,
        distanceMeters: tour.distance_meters,
        totalTimeSeconds: tour.total_time_seconds,
        price: tour.price,
        rating: tour.rating,
        path: tour.path,
      });
    } catch (err) {
      this.logger.error('Falha ao despachar email de resumo do passeio', err);
    }
  }

  private generateCode(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  private getQrSecret(): string {
    const secret = process.env.TOUR_QR_SECRET;
    if (!secret) {
      throw new BadRequestException('Configuração de QR indisponível');
    }
    return secret;
  }

  private getQrTtlSeconds(): number {
    const raw = process.env.TOUR_QR_TTL_SECONDS;
    const ttl = raw ? Number(raw) : 300;
    return Number.isFinite(ttl) && ttl > 0 ? ttl : 300;
  }

  private signQrPayload(payloadBase64: string): string {
    return createHmac('sha256', this.getQrSecret())
      .update(payloadBase64)
      .digest('base64url');
  }

  private generateTerminationQrToken({
    tourIdentifier,
    walkerIdentifier,
    tutorIdentifier,
  }: {
    tourIdentifier: string;
    walkerIdentifier: string;
    tutorIdentifier: string;
  }): { token: string; nonce: string; expiresAt: Date } {
    const nonce = randomUUID();
    const expiresAt = new Date(Date.now() + this.getQrTtlSeconds() * 1000);
    const payload = {
      tour_identifier: tourIdentifier,
      walker_identifier: walkerIdentifier,
      tutor_identifier: tutorIdentifier,
      nonce,
      exp: Math.floor(expiresAt.getTime() / 1000),
    };
    const payloadBase64 = Buffer.from(JSON.stringify(payload)).toString(
      'base64url',
    );
    const signature = this.signQrPayload(payloadBase64);
    return { token: `${payloadBase64}.${signature}`, nonce, expiresAt };
  }

  private assertTerminationQrToken({
    token,
    tourIdentifier,
    walkerIdentifier,
    tutorIdentifier,
    expectedNonce,
    expiresAt,
  }: {
    token: string;
    tourIdentifier: string;
    walkerIdentifier: string;
    tutorIdentifier: string;
    expectedNonce: string | null;
    expiresAt: Date | null;
  }): void {
    if (!expectedNonce || !expiresAt) {
      throw new BadRequestException('QR de encerramento ainda não foi gerado');
    }
    if (expiresAt.getTime() <= Date.now()) {
      throw new BadRequestException('QR de encerramento expirado');
    }

    const [payloadBase64, signature] = token.split('.');
    if (!payloadBase64 || !signature) {
      throw new BadRequestException('QR de encerramento inválido');
    }

    const expectedSignature = this.signQrPayload(payloadBase64);
    const signatureBuffer = Buffer.from(signature);
    const expectedBuffer = Buffer.from(expectedSignature);
    if (
      signatureBuffer.length !== expectedBuffer.length ||
      !timingSafeEqual(signatureBuffer, expectedBuffer)
    ) {
      throw new BadRequestException('QR de encerramento inválido');
    }

    type TerminationQrPayload = {
      tour_identifier: string;
      walker_identifier: string;
      tutor_identifier: string;
      nonce: string;
      exp: number;
    };
    let payload: TerminationQrPayload;
    try {
      payload = JSON.parse(
        Buffer.from(payloadBase64, 'base64url').toString('utf8'),
      ) as TerminationQrPayload;
    } catch {
      throw new BadRequestException('QR de encerramento inválido');
    }

    if (
      payload.tour_identifier !== tourIdentifier ||
      payload.walker_identifier !== walkerIdentifier ||
      payload.tutor_identifier !== tutorIdentifier ||
      payload.nonce !== expectedNonce
    ) {
      throw new BadRequestException('QR de encerramento inválido');
    }
    if (payload.exp * 1000 <= Date.now()) {
      throw new BadRequestException('QR de encerramento expirado');
    }
  }
}
