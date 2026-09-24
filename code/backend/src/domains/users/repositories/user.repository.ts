import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { UserEntity, UserRole } from '../entities/user.entity';
import { TutorEntity } from '../../tutors/entities/tutor.entity';
import { WalkerEntity } from '../../walkers/entities/walker.entity';

@Injectable()
export class UserRepository {
  constructor(
    @InjectRepository(UserEntity)
    private readonly repository: Repository<UserEntity>,
    private readonly dataSource: DataSource,
  ) {}

  async findByEmail(email: string): Promise<UserEntity | null> {
    return this.repository.findOneBy({ email });
  }

  async findById(identifier: string): Promise<UserEntity | null> {
    return this.repository.findOne({
      where: { identifier },
      select: ['identifier', 'name', 'email', 'role'],
    });
  }

  async findAll(): Promise<UserEntity[]> {
    return this.repository.find({
      select: ['identifier', 'name', 'email', 'role'],
    });
  }

  async createWithProfile(data: {
    identifier: string;
    name: string;
    email: string;
    password: string;
    role: UserEntity['role'];
  }): Promise<UserEntity> {
    const ProfileEntity =
      data.role === UserRole.TUTOR ? TutorEntity : WalkerEntity;

    return this.dataSource.transaction(async (manager) => {
      const user = manager.create(UserEntity, {
        identifier: data.identifier,
        name: data.name,
        email: data.email,
        password: data.password,
        role: data.role,
      });
      await manager.save(user);

      const profile = manager.create(ProfileEntity, {
        identifier: data.identifier,
        user,
      });
      await manager.save(profile);

      return user;
    });
  }

  async update(identifier: string, data: Partial<UserEntity>): Promise<void> {
    await this.repository.update(identifier, data);
  }

  async delete(identifier: string): Promise<void> {
    await this.repository.delete(identifier);
  }
}
