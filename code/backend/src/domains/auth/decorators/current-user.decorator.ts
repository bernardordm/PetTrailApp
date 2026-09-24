import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { IAuthenticatedUser } from '../interfaces/auth.interface';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): IAuthenticatedUser => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
