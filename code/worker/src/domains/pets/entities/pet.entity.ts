import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import { TutorEntity } from '../../tutors/entities/tutor.entity';

@Entity('pets')
export class PetEntity {
  @PrimaryColumn()
  identifier: string;

  @Column()
  name: string;

  @Column()
  species: string;

  @Column()
  size: string;

  @Column({ type: 'varchar', nullable: true })
  age: string | null;

  @Column({ type: 'varchar', name: 'photo_url', nullable: true })
  photo_url: string | null;

  @Column({ type: 'bytea', name: 'photo_data', nullable: true, select: false })
  photo_data: Buffer | null;

  @Column({ type: 'varchar', name: 'photo_mime_type', nullable: true, select: false })
  photo_mime_type: string | null;

  @Column({ type: 'int', name: 'photo_size', nullable: true, select: false })
  photo_size: number | null;

  @Column({ type: 'varchar', name: 'photo_hash', nullable: true, select: false })
  photo_hash: string | null;

  @Column({ name: 'tutor_identifier' })
  tutor_identifier: string;

  @ManyToOne(() => TutorEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tutor_identifier' })
  tutor: TutorEntity;

  @Column({ type: 'text', nullable: true })
  observations: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;
}
