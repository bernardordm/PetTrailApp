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
import { TutorsService } from '../services/tutors.service';
import { UpdateTutorDto } from '../dtos/update-tutor.dto';
import { JwtAuthGuard } from '../../auth/jwt/jwt.auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { IAuthenticatedUser } from '../../auth/interfaces/auth.interface';
import type { Response } from 'express';
import type { MulterMemoryFile } from '../../../app/types/multer-memory-file';

@UseGuards(JwtAuthGuard)
@Controller('tutors')
export class TutorsController {
  constructor(private readonly tutorsService: TutorsService) {}

  private ensureProfileAccess(
    identifier: string,
    user: IAuthenticatedUser,
  ): void {
    if (identifier !== user.identifier) {
      throw new ForbiddenException(
        'Você não tem permissão para acessar o perfil deste tutor',
      );
    }
  }

  @Get()
  async findAll() {
    return this.tutorsService.findAll();
  }

  @Get('/:identifier')
  async findOne(@Param('identifier') id: string) {
    return this.tutorsService.findOne(id);
  }

  @Patch('/:identifier')
  async update(@Param('identifier') id: string, @Body() dto: UpdateTutorDto) {
    return this.tutorsService.update(id, dto);
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

    return this.tutorsService.updatePhoto(
      id,
      file.buffer,
      file.mimetype,
      file.size,
    );
  }

  @Get('/:identifier/photo')
  async getPhoto(
    @Param('identifier') id: string,
    @CurrentUser() user: IAuthenticatedUser,
    @Res() res: Response,
  ) {
    this.ensureProfileAccess(id, user);

    const photo = await this.tutorsService.getPhoto(id);
    res.setHeader('Content-Type', photo.mimeType);
    res.setHeader('Cache-Control', 'public, max-age=86400');
    return res.send(photo.data);
  }
}
