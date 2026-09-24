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

@Entity('walkers')
export class WalkerEntity {
  @PrimaryColumn()
  identifier: string;

  @OneToOne(() => UserEntity, (user) => user.walker, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'identifier' })
  user: UserEntity;

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

  @Column({ unique: true, nullable: true })
  document: string;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    name: 'walk_price',
    nullable: true,
  })
  walkPrice: number;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    name: 'average_ride_time',
    nullable: true,
  })
  averageRideTime: number;

  @Column({ default: true })
  available: boolean;

  @Column({ type: 'varchar', length: 10, default: 'idle' })
  status: 'idle' | 'pending' | 'on_tour';

  @Column({
    type: 'decimal',
    precision: 3,
    scale: 2,
    name: 'average_rating',
    nullable: true,
  })
  averageRating: number | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;
}
