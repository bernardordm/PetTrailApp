import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import configuration from './app/config/config';
import { getDatabaseConfig } from './app/config/db.config';
import { FirebaseModule } from './app/firebase/firebase.module';
import { AuthModule } from './domains/auth/auth.module';
import { ToursModule } from './domains/tours/tours.module';

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
    AuthModule,
    ToursModule,
  ],
})
export class AppModule implements NestModule {
  configure(_consumer: MiddlewareConsumer) {}
}
