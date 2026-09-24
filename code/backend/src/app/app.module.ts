import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { LoggerMiddleware } from './middlewares/logger.middleware';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { getDatabaseConfig } from './config/db.config';
import configuration from './config/config';
import { UserModule } from '../domains/users/user.module';
import { TutorsModule } from '../domains/tutors/tutors.module';
import { WalkerModule } from '../domains/walkers/walker.module';
import { AuthModule } from '../domains/auth/auth.module';
import { PetsModule } from '../domains/pets/pets.module';
import { ToursModule } from '../domains/tours/tours.module';
import { FirebaseModule } from './firebase/firebase.module';
import { ChatModule } from '../domains/chat/chat.module';
import { ReportsModule } from '../domains/reports/reports.module';

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
    FirebaseModule,
    UserModule,
    TutorsModule,
    WalkerModule,
    PetsModule,
    ToursModule,
    AuthModule,
    ChatModule,
    ReportsModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('*');
  }
}
