import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { WalkersService } from '../services/walkers.service';
import { UpdateWalkerDto } from '../dtos/update-walker.dto';
import { JwtAuthGuard } from '../../auth/jwt/jwt.auth.guard';
import { AvailabilityWalkerDto } from '../dtos/availability-walker.dto';
import { LocationWalkerDto } from '../dtos/location-walker.dto';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { IAuthenticatedUser } from '../../auth/interfaces/auth.interface';
import type { Response } from 'express';
import type { MulterMemoryFile } from '../../../app/types/multer-memory-file';

@UseGuards(JwtAuthGuard)
@Controller('walkers')
export class WalkersController {
  constructor(private readonly walkersService: WalkersService) {}

  private ensureProfileAccess(
    identifier: string,
    user: IAuthenticatedUser,
  ): void {
    if (identifier !== user.identifier) {
      throw new ForbiddenException(
        'Você não tem permissão para acessar o perfil deste passeador',
      );
    }
  }

  @Get()
  async findAll() {
    return this.walkersService.findAll();
  }

  @Get('/:identifier')
  async findOne(@Param('identifier') id: string) {
    return this.walkersService.findOne(id);
  }

  @Get('pin/:identifier')
  async findOneForPin(@Param('identifier') identifier: string) {
    return this.walkersService.findOneForPin(identifier);
  }

  @Patch('available/:identifier')
  async activateAvailable(
    @Param('identifier') id: string,
    @Body() dto: AvailabilityWalkerDto,
  ) {
    return this.walkersService.activatedAvailable(id, dto);
  }

  @Patch('location/:identifier')
  async updateLocation(
    @Param('identifier') id: string,
    @Body() dto: LocationWalkerDto,
  ) {
    return this.walkersService.updateLocation(id, dto);
  }

  @Patch('/:identifier')
  async update(@Param('identifier') id: string, @Body() dto: UpdateWalkerDto) {
    return this.walkersService.update(id, dto);
  }

  @Post('/:identifier/photo')
  @UseInterceptors(
    FileInterceptor('photo', {
      storage: memoryStorage(),
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/^image\/(jpeg|png|webp|gif)$/)) {
          cb(new Error('Apenas imagens são permitidas'), false);
          return;
        }
        cb(null, true);
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadPhoto(
    @Param('identifier') id: string,
    @UploadedFile() file: MulterMemoryFile,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    this.ensureProfileAccess(id, user);
    if (!file) throw new BadRequestException('Foto inválida');

    return this.walkersService.updatePhoto(
      id,
      file.buffer,
      file.mimetype,
      file.size,
    );
  }

  @Get('/:identifier/photo')
  async getPhoto(
    @Param('identifier') id: string,
    @Res() res: Response,
  ) {
    const photo = await this.walkersService.getPhoto(id);
    res.setHeader('Content-Type', photo.mimeType);
    res.setHeader('Cache-Control', 'public, max-age=86400');
    return res.send(photo.data);
  }
}
