import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WalkerEntity } from './entities/walker.entity';
import { WalkerRepository } from './repositories/walker.repository';

@Module({
  imports: [TypeOrmModule.forFeature([WalkerEntity])],
  providers: [WalkerRepository],
  exports: [WalkerRepository],
})
export class WalkerModule {}
