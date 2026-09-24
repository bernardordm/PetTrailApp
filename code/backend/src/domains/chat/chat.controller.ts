import {
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt/jwt.auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { IAuthenticatedUser } from '../auth/interfaces/auth.interface';
import { ChatService } from './chat.service';

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('tours/:tour_id/messages')
  getMessages(
    @Param('tour_id') tourId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(30), ParseIntPipe) limit: number,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    return this.chatService.getHistory(tourId, user.identifier, page, limit);
  }
}
