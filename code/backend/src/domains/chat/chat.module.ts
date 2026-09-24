import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MessageEntity } from './entities/message.entity';
import { TourEntity } from '../tours/entities/tour.entity';
import { MessageRepository } from './repositories/message.repository';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';

@Module({
  imports: [TypeOrmModule.forFeature([MessageEntity, TourEntity])],
  controllers: [ChatController],
  providers: [MessageRepository, ChatService],
})
export class ChatModule {}
