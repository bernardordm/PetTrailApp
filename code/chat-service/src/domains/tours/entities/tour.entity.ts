import { Column, Entity, PrimaryColumn } from 'typeorm';
import { TourStatus } from '../enums/tour-status.enum';

@Entity('tours')
export class TourEntity {
  @PrimaryColumn()
  identifier: string;

  @Column({ type: 'varchar' })
  status: TourStatus;

  @Column({ name: 'walker_identifier' })
  walker_identifier: string;

  @Column({ name: 'tutor_identifier' })
  tutor_identifier: string;
}
