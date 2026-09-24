import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { createId } from '@paralleldrive/cuid2';
import { IUser, ICreateUser, IUpdateUser } from '../interfaces/user.interface';
import { UserRepository } from '../repositories/user.repository';

@Injectable()
export class UsersService {
  constructor(private readonly userRepository: UserRepository) {}

  async create(dto: ICreateUser): Promise<IUser> {
    const existing = await this.userRepository.findByEmail(dto.email);
    if (existing) throw new ConflictException('Email already in use');

    const identifier = createId();
    const password = await bcrypt.hash(dto.password, 10);

    return this.userRepository.createWithProfile({
      identifier,
      name: dto.name,
      email: dto.email,
      password,
      role: dto.role,
    });
  }

  async findAll(): Promise<IUser[]> {
    return this.userRepository.findAll();
  }

  async findOne(identifier: string): Promise<IUser> {
    const user = await this.userRepository.findById(identifier);
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async update(identifier: string, dto: IUpdateUser): Promise<IUser> {
    const user = await this.userRepository.findById(identifier);
    if (!user) throw new NotFoundException('User not found');

    const data: IUpdateUser = {};

    if (dto.password) {
      data.password = await bcrypt.hash(dto.password, 10);
    }

    await this.userRepository.update(identifier, data);
    return this.findOne(identifier);
  }

  async remove(identifier: string): Promise<void> {
    const user = await this.userRepository.findById(identifier);
    if (!user) throw new NotFoundException('User not found');
    await this.userRepository.delete(identifier);
  }
}
