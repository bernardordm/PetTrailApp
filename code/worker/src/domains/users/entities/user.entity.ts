import { Column, Entity, OneToOne, PrimaryColumn } from 'typeorm';
import { TutorEntity } from '../../tutors/entities/tutor.entity';
import { WalkerEntity } from '../../walkers/entities/walker.entity';

export enum UserRole {
  TUTOR = 'tutor',
  WALKER = 'walker',
}

@Entity('users')
export class UserEntity {
  @PrimaryColumn({ type: 'varchar' })
  identifier: string;

  @Column()
  name: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column({ type: 'varchar', default: 'tutor' })
  role: UserRole;

  @OneToOne(() => TutorEntity, (tutor) => tutor.user)
  tutor: TutorEntity;

  @OneToOne(() => WalkerEntity, (walker) => walker.user)
  walker: WalkerEntity;
}
