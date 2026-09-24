import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import configuration from './config/config';
import { getDatabaseConfig } from './config/db.config';
import { ChatModule } from '../domains/chat/chat.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      load: [configuration],
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      useFactory: () => getDatabaseConfig(),
    }),
    ChatModule,
  ],
})
export class AppModule {}
