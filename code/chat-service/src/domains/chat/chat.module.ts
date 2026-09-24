import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { MessageEntity } from './entities/message.entity';
import { TourEntity } from '../tours/entities/tour.entity';
import { MessageRepository } from './repositories/message.repository';
import { TourRepository } from '../tours/repositories/tour.repository';
import { ChatService } from './chat.service';
import { ChatPublisher } from './chat.publisher';
import { ChatConsumer } from './chat.consumer';
import { ChatGateway } from './chat.gateway';

@Module({
  imports: [
    TypeOrmModule.forFeature([MessageEntity, TourEntity]),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('jwt.secret'),
      }),
    }),
  ],
  providers: [
    MessageRepository,
    TourRepository,
    ChatService,
    ChatPublisher,
    ChatConsumer,
    ChatGateway,
  ],
})
export class ChatModule {}
