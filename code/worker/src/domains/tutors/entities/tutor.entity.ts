import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserEntity } from '../../users/entities/user.entity';

@Entity('tutors')
export class TutorEntity {
  @PrimaryColumn()
  identifier: string;

  @OneToOne(() => UserEntity, (user) => user.tutor, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'identifier' })
  user: UserEntity;

  @Column({ nullable: true })
  address: string;

  @Column({ nullable: true })
  phone: string;

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

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;
}
