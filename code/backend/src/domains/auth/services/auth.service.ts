import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { UserRepository } from '../../users/repositories/user.repository';
import { IAuthLogin, IJwtPayload } from '../interfaces/auth.interface';
import { IUser } from '../../users/interfaces/user.interface';

@Injectable()
export class AuthService {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly jwtService: JwtService,
  ) {}

  async validateUser(email: string, password: string): Promise<IUser> {
    const user = await this.userRepository.findByEmail(email);
    if (!user) throw new UnauthorizedException('Credenciais Inválidas');

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) throw new UnauthorizedException('Credenciais Inválidas');

    return user;
  }

  login(user: IUser): IAuthLogin {
    const payload: IJwtPayload = { sub: user.identifier, role: user.role };
    return {
      identifier: user.identifier,
      name: user.name,
      email: user.email,
      role: user.role,
      accessToken: this.jwtService.sign(payload),
    };
  }
}
