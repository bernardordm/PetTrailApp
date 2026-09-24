import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { IJwtPayload, IAuthenticatedUser } from '../interfaces/auth.interface';

function cookieTokenExtractor(request: {
  headers?: { cookie?: string };
}): string | null {
  const cookieHeader = request?.headers?.cookie;
  if (!cookieHeader) return null;

  const tokenCookie = cookieHeader
    .split(';')
    .map((cookie) => cookie.trim())
    .find((cookie) => cookie.startsWith('token='));

  if (!tokenCookie) return null;
  return decodeURIComponent(tokenCookie.split('=').slice(1).join('='));
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromExtractors([
        ExtractJwt.fromAuthHeaderAsBearerToken(),
        cookieTokenExtractor,
      ]),
      ignoreExpiration: false,
      secretOrKey: configService.get('jwt.secret', 'secret'),
    });
  }

  validate(payload: IJwtPayload): IAuthenticatedUser {
    return { identifier: payload.sub, role: payload.role };
  }
}
