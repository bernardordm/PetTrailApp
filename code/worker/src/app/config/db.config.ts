import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as path from 'path';

export function getDatabaseConfig(): TypeOrmModuleOptions {
  return {
    type: 'postgres',
    host: process.env.DB_HOST,
    port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 5432,
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    entities: [path.join(__dirname, '../..') + '/domains/**/*.entity{.ts,.js}'],
    autoLoadEntities: true,
    synchronize: false,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    logging: false,
    extra: {
      options: '-c timezone=America/Sao_Paulo',
    },
  };
}
