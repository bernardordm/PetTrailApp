import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { IWalker, IUpdateWalker } from '../interfaces/walker.interface';
import { LocationWalkerDto } from '../dtos/location-walker.dto';
import { WalkerRepository } from '../repositories/walker.repository';
import { FirebaseService } from '../../../app/firebase/firebase.service';
import { createHash } from 'crypto';

@Injectable()
export class WalkersService {
  constructor(
    private readonly walkerRepository: WalkerRepository,
    private readonly firebaseService: FirebaseService,
  ) {}

  async findAll(): Promise<IWalker[]> {
    return this.walkerRepository.findAll();
  }

  async findOne(identifier: string): Promise<IWalker> {
    const walker = await this.walkerRepository.findById(identifier);
    if (!walker) throw new NotFoundException('Walker not found');
    return walker;
  }

  async findOneForPin(identifier: string): Promise<IWalker> {
    const walker = await this.walkerRepository.findByIdForPin(identifier);
    if (!walker) throw new NotFoundException('Walker not found');
    return walker;
  }

  async update(identifier: string, dto: IUpdateWalker): Promise<IWalker> {
    const walker = await this.walkerRepository.findById(identifier);
    if (!walker) throw new NotFoundException('Walker not found');
    await this.walkerRepository.update(identifier, dto);
    return (await this.walkerRepository.findById(identifier)) as IWalker;
  }

  async updatePhoto(
    identifier: string,
    fileBuffer: Buffer,
    mimeType: string,
    fileSize: number,
  ): Promise<IWalker> {
    const walker = await this.walkerRepository.findById(identifier);
    if (!walker) throw new NotFoundException('Walker not found');
    if (!fileBuffer.length) {
      throw new BadRequestException('Arquivo de imagem inválido');
    }

    const photoHash = createHash('sha256').update(fileBuffer).digest('hex');
    const photoUrl = `/walkers/${identifier}/photo`;

    await this.walkerRepository.update(identifier, {
      photo_url: photoUrl,
      photo_data: fileBuffer,
      photo_mime_type: mimeType,
      photo_size: fileSize,
      photo_hash: photoHash,
    });

    return (await this.walkerRepository.findById(identifier)) as IWalker;
  }

  async getPhoto(
    identifier: string,
  ): Promise<{ data: Buffer; mimeType: string }> {
    const walker = await this.walkerRepository.findPhotoById(identifier);
    if (!walker) throw new NotFoundException('Walker not found');
    if (!walker.photo_data || !walker.photo_mime_type) {
      throw new NotFoundException('Foto do passeador não encontrada');
    }

    return {
      data: walker.photo_data,
      mimeType: walker.photo_mime_type,
    };
  }

  async activatedAvailable(
    identifier: string,
    dto: IUpdateWalker,
  ): Promise<IWalker> {
    const walker = await this.walkerRepository.findById(identifier);
    if (!walker) throw new NotFoundException('Walker not found');

    if (dto.available) {
      await this.walkerRepository.update(identifier, {
        available: true,
        status: 'idle',
      });
      await this.firebaseService.initWalkerLocation(identifier, {
        name: walker.user?.name ?? '',
        available: true,
        status: 'idle',
      });
    } else {
      await this.walkerRepository.update(identifier, {
        available: false,
        status: 'idle',
      });
      await this.firebaseService.clearWalkerLocation(identifier);
    }

    return (await this.walkerRepository.findById(identifier)) as IWalker;
  }

  async updateLocation(
    identifier: string,
    dto: LocationWalkerDto,
  ): Promise<IWalker> {
    const walker = await this.walkerRepository.findById(identifier);
    if (!walker) throw new NotFoundException('Walker not found');
    if (!walker.available)
      throw new NotFoundException('Walker is not available');
    if (walker.status !== 'idle' && walker.status !== 'on_tour')
      return walker as IWalker;

    await this.firebaseService.updateWalkerCoords(identifier, {
      name: walker.user?.name ?? '',
      available: true,
      status: walker.status as 'idle' | 'pending' | 'on_tour',
      latitude: dto.latitude,
      longitude: dto.longitude,
      updatedAt: Date.now(),
    });

    return walker as IWalker;
  }
}
