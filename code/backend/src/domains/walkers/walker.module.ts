import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WalkerEntity } from './entities/walker.entity';
import { WalkerRepository } from './repositories/walker.repository';
import { WalkersService } from './services/walkers.service';
import { WalkersController } from './controllers/walkers.controller';
import { FirebaseModule } from '../../app/firebase/firebase.module';

@Module({
  imports: [TypeOrmModule.forFeature([WalkerEntity]), FirebaseModule],
  controllers: [WalkersController],
  providers: [WalkerRepository, WalkersService],
  exports: [WalkerRepository, WalkersService],
})
export class WalkerModule {}
