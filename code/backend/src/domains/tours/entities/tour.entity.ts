import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import { WalkerEntity } from '../../walkers/entities/walker.entity';
import { TutorEntity } from '../../tutors/entities/tutor.entity';
import { PetEntity } from '../../pets/entities/pet.entity';
import { TourStatus } from '../enums/tour-status.enum';

@Entity('tours')
export class TourEntity {
  @PrimaryColumn()
  identifier: string;

  @Column({ type: 'varchar', default: TourStatus.WAITING_ACCEPTANCE })
  status: TourStatus;

  @Column({ type: 'varchar', name: 'confirmation_code', nullable: true })
  confirmation_code: string | null;

  @Column({ type: 'timestamp', name: 'started_at', nullable: true })
  started_at: Date | null;

  @Column({ type: 'timestamp', name: 'finished_at', nullable: true })
  finished_at: Date | null;

  @Column({ name: 'walker_identifier' })
  walker_identifier: string;

  @ManyToOne(() => WalkerEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'walker_identifier' })
  walker: WalkerEntity;

  @Column({ name: 'tutor_identifier' })
  tutor_identifier: string;

  @ManyToOne(() => TutorEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tutor_identifier' })
  tutor: TutorEntity;

  @Column({ name: 'pet_identifier' })
  pet_identifier: string;

  @ManyToOne(() => PetEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'pet_identifier' })
  pet: PetEntity;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  price: number | null;

  @Column({ type: 'varchar', name: 'termination_code', nullable: true })
  termination_code: string | null;

  @Column({ type: 'varchar', name: 'termination_qr_nonce', nullable: true })
  termination_qr_nonce: string | null;

  @Column({
    type: 'timestamp',
    name: 'termination_qr_expires_at',
    nullable: true,
  })
  termination_qr_expires_at: Date | null;

  @Column({ type: 'int', name: 'total_time_seconds', nullable: true })
  total_time_seconds: number | null;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    name: 'distance_meters',
    nullable: true,
  })
  distance_meters: number | null;

  @Column({ type: 'jsonb', nullable: true })
  path: object | null;

  @Column({ type: 'int', nullable: true })
  rating: number | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;
}
