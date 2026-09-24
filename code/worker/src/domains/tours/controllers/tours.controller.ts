import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ToursService } from '../services/tours.service';
import { ConfirmTourDto } from '../dtos/confirm-tour.dto';
import { StartTourDto } from '../dtos/start-tour.dto';
import { GenerateTerminationCodeDto } from '../dtos/generate-termination-code.dto';
import { FinishTourDto } from '../dtos/finish-tour.dto';
import { RateTourDto } from '../dtos/rate-tour.dto';
import { JwtAuthGuard } from '../../auth/jwt/jwt.auth.guard';
import { FirebaseService } from '../../../app/firebase/firebase.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { IAuthenticatedUser } from '../../auth/interfaces/auth.interface';

@UseGuards(JwtAuthGuard)
@Controller('tours')
export class ToursController {
  constructor(
    private readonly toursService: ToursService,
    private readonly firebaseService: FirebaseService,
  ) {}

  @Get('/my')
  async getMyTours(@CurrentUser() currentUser: IAuthenticatedUser) {
    return this.toursService.getMyTours(currentUser);
  }

  @Get('/my/last-completed')
  async getMyLastCompletedTour(@CurrentUser() currentUser: IAuthenticatedUser) {
    return this.toursService.getMyLastCompletedTour(currentUser);
  }

  @Get('/:identifier')
  async getTourById(
    @Param('identifier') identifier: string,
    @CurrentUser() currentUser: IAuthenticatedUser,
  ) {
    return this.toursService.getTourById(identifier, currentUser);
  }

  @Patch('/:identifier/confirm')
  async confirmRequest(
    @Param('identifier') identifier: string,
    @Body() dto: ConfirmTourDto,
  ) {
    return this.toursService.confirmRequest(identifier, dto);
  }

  @Patch('/:identifier/start')
  async startRequest(
    @Param('identifier') identifier: string,
    @Body() dto: StartTourDto,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    return this.toursService.startRequest(identifier, dto, user);
  }

  @Patch('/:identifier/clear')
  async clearRequest(@Param('identifier') identifier: string) {
    return this.firebaseService.clearTutorTourNotification(identifier);
  }

  @Post('/:identifier/sync-active')
  async syncActiveTour(
    @Param('identifier') identifier: string,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    await this.toursService.syncActiveTour(identifier, user);
    return { ok: true };
  }

  @Post('/:identifier/generate-termination-code')
  async generateTerminationCode(
    @Param('identifier') identifier: string,
    @Body() dto: GenerateTerminationCodeDto,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    return this.toursService.generateTerminationCode(identifier, dto, user);
  }

  @Patch('/:identifier/finish')
  async finishTour(
    @Param('identifier') identifier: string,
    @Body() dto: FinishTourDto,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    return this.toursService.finishTour(identifier, dto, user);
  }

  @Patch('/:identifier/rate')
  async rateTour(
    @Param('identifier') identifier: string,
    @Body() dto: RateTourDto,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    return await this.toursService.rateTour(identifier, dto.rating, user);
  }
}
