import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { WalkerRepository } from '../../walkers/repositories/walker.repository';
import { TutorRepository } from '../../tutors/repositories/tutor.repository';
import { PetRepository } from '../../pets/repositories/pet.repository';
import { TourPublisher } from '../publishers/tour.publisher';
import { ICreateTour } from '../interfaces/tour.interface';

@Injectable()
export class ToursService {
  constructor(
    private readonly walkerRepository: WalkerRepository,
    private readonly tutorRepository: TutorRepository,
    private readonly petRepository: PetRepository,
    private readonly tourPublisher: TourPublisher,
  ) {}

  async createRequest(dto: ICreateTour): Promise<void> {
    const walker = await this.walkerRepository.findById(dto.walker_identifier);
    if (!walker) throw new NotFoundException('Passeador não encontrado');
    if (!walker.available || walker.status !== 'idle')
      throw new BadRequestException('Passeador não está disponível no momento');

    const tutor = await this.tutorRepository.findById(dto.tutor_identifier);
    if (!tutor) throw new NotFoundException('Tutor não encontrado');

    const pet = await this.petRepository.findById(dto.pet_identifier);
    if (!pet) throw new NotFoundException('Pet não encontrado');

    await this.tourPublisher.dispatch(dto);
  }
}
