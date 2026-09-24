import {
  BadRequestException,
  Body,
  Controller,
  Delete,
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
import { PetsService } from '../services/pets.service';
import { CreatePetDto } from '../dtos/create-pet.dto';
import { UpdatePetDto } from '../dtos/update-pet.dto';
import { JwtAuthGuard } from '../../auth/jwt/jwt.auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { IAuthenticatedUser } from '../../auth/interfaces/auth.interface';
import type { Response } from 'express';
import type { MulterMemoryFile } from '../../../app/types/multer-memory-file';

@UseGuards(JwtAuthGuard)
@Controller('tutors/:tutorIdentifier/pets')
export class PetsController {
  constructor(private readonly petsService: PetsService) {}

  private ensureTutorAccess(
    tutorIdentifier: string,
    user: IAuthenticatedUser,
  ): void {
    if (tutorIdentifier !== user.identifier) {
      throw new ForbiddenException(
        'Você não tem permissão para acessar os pets deste tutor',
      );
    }
  }

  @Post()
  async create(
    @Param('tutorIdentifier') tutorIdentifier: string,
    @Body() dto: CreatePetDto,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    this.ensureTutorAccess(tutorIdentifier, user);
    return this.petsService.create(dto, tutorIdentifier);
  }

  @Get()
  async findAll(
    @Param('tutorIdentifier') tutorIdentifier: string,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    this.ensureTutorAccess(tutorIdentifier, user);
    return this.petsService.findAllByTutor(tutorIdentifier);
  }

  @Get(':identifier')
  async findOne(
    @Param('tutorIdentifier') tutorIdentifier: string,
    @Param('identifier') id: string,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    this.ensureTutorAccess(tutorIdentifier, user);
    return this.petsService.findOne(id, tutorIdentifier);
  }

  @Patch(':identifier')
  async update(
    @Param('tutorIdentifier') tutorIdentifier: string,
    @Param('identifier') id: string,
    @Body() dto: UpdatePetDto,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    this.ensureTutorAccess(tutorIdentifier, user);
    return this.petsService.update(id, dto, tutorIdentifier);
  }

  @Delete(':identifier')
  async remove(
    @Param('tutorIdentifier') tutorIdentifier: string,
    @Param('identifier') id: string,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    this.ensureTutorAccess(tutorIdentifier, user);
    return this.petsService.remove(id, tutorIdentifier);
  }

  @Post(':identifier/photo')
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
    @Param('tutorIdentifier') tutorIdentifier: string,
    @Param('identifier') id: string,
    @UploadedFile() file: MulterMemoryFile,
    @CurrentUser() user: IAuthenticatedUser,
  ) {
    this.ensureTutorAccess(tutorIdentifier, user);
    if (!file) {
      throw new BadRequestException('Foto inválida');
    }

    return this.petsService.updatePhoto(
      id,
      file.buffer,
      file.mimetype,
      file.size,
      tutorIdentifier,
    );
  }

  @Get(':identifier/photo')
  async getPhoto(
    @Param('tutorIdentifier') tutorIdentifier: string,
    @Param('identifier') id: string,
    @Res() res: Response,
  ) {
    const photo = await this.petsService.getPhoto(id, tutorIdentifier);
    res.setHeader('Content-Type', photo.mimeType);
    res.setHeader('Cache-Control', 'public, max-age=86400');
    return res.send(photo.data);
  }
}
