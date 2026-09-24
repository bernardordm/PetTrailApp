import { Column, CreateDateColumn, Entity, PrimaryColumn } from 'typeorm';

@Entity('messages')
export class MessageEntity {
  @PrimaryColumn()
  identifier: string;

  @Column()
  tour_id: string;

  @Column()
  sender_id: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'timestamptz' })
  sent_at: Date;

  @Column({ type: 'timestamptz', nullable: true })
  delivered_at: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
