import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { ToursService } from '../services/tours.service';
import { CreateTourDto } from '../dtos/create-tour.dto';
import { JwtAuthGuard } from '../../auth/jwt/jwt.auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('tours')
export class ToursController {
  constructor(private readonly toursService: ToursService) {}

  @Post('/new')
  @HttpCode(202)
  async createRequest(@Body() dto: CreateTourDto): Promise<void> {
    await this.toursService.createRequest(dto);
  }
}
