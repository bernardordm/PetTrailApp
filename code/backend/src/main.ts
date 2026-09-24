import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { ConfigService } from '@nestjs/config';
import { ValidationPipe } from '@nestjs/common';
import * as express from 'express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['log', 'error', 'warn', 'debug'],
  });
  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 3001);

  app.useGlobalPipes(new ValidationPipe({ whitelist: true }));

  app.enableCors({
    origin: [
      'https://pettrail.vercel.app',
      'https://pmg-es-2026-1-ti5-6904100-pet-trail-98befvveo.vercel.app',
      'http://localhost:3000',
    ],
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  app.use('/uploads', express.static(join(process.cwd(), 'uploads')));

  await app.listen(port);
  console.log(`Application is running on: ${await app.getUrl()}`);
}
void bootstrap(); // ci test
