import { Injectable } from '@nestjs/common';
import * as ExcelJS from 'exceljs';
import { ReportsRepository } from '../repositories/reports.repositories';
import { GetReportsQueryDto } from '../dtos/get-reports-query.dto';
import { TourStatus } from '../../tours/enums/tour-status.enum';

export interface WalkerReportMetrics {
  period: {
    startDate: string | null;
    endDate: string | null;
  };
  totalEarnings: number;
  totalDistanceMeters: number;
  totalTimeSeconds: number;
  completionRate: number;
  averageTimeSeconds: number;
  averageDistanceMeters: number;
  averageRating: number;
}

@Injectable()
export class ReportsService {
  constructor(private readonly reportsRepository: ReportsRepository) {}

  async getWalkerReport(
    walkerIdentifier: string,
    query: GetReportsQueryDto,
  ): Promise<WalkerReportMetrics> {
    const { startDate, endDate } = this.resolveDateRange(query);

    const raw = await this.reportsRepository.getWalkerMetrics(
      walkerIdentifier,
      startDate,
      endDate,
    );

    const totalTours = parseInt(raw.total_tours ?? '0', 10) || 0;
    const finishedTours = parseInt(raw.finished_tours ?? '0', 10) || 0;

    return {
      period: {
        startDate: startDate?.toISOString() ?? null,
        endDate: endDate?.toISOString() ?? null,
      },
      totalEarnings: parseFloat(raw.total_earnings ?? '0') || 0,
      totalDistanceMeters: parseFloat(raw.total_distance_meters ?? '0') || 0,
      totalTimeSeconds: parseInt(raw.total_time_seconds ?? '0', 10) || 0,
      completionRate:
        totalTours > 0
          ? Math.round((finishedTours / totalTours) * 10000) / 100
          : 0,
      averageTimeSeconds: parseFloat(raw.avg_time_seconds ?? '0') || 0,
      averageDistanceMeters: parseFloat(raw.avg_distance_meters ?? '0') || 0,
      averageRating: parseFloat(raw.avg_rating ?? '0') || 0,
    };
  }

  async exportWalkerToursXlsx(
    walkerIdentifier: string,
    query: GetReportsQueryDto,
  ): Promise<Buffer> {
    const { startDate, endDate } = this.resolveDateRange(query);
    const rows = await this.reportsRepository.getWalkerToursForExport(
      walkerIdentifier,
      startDate,
      endDate,
    );

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Passeios');

    sheet.columns = [
      { header: 'Pet', key: 'pet_name', width: 20 },
      { header: 'Tutor', key: 'tutor_name', width: 25 },
      { header: 'Início', key: 'started_at', width: 22 },
      { header: 'Fim', key: 'finished_at', width: 22 },
      { header: 'Distância (m)', key: 'distance_meters', width: 16 },
      { header: 'Tempo (s)', key: 'total_time_seconds', width: 14 },
      { header: 'Valor (R$)', key: 'price', width: 14 },
      { header: 'Status', key: 'status', width: 22 },
    ];

    const headerRow = sheet.getRow(1);
    headerRow.font = { bold: true };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFD9E1F2' },
    };

    const statusLabels: Record<string, string> = {
      [TourStatus.WAITING_ACCEPTANCE]: 'Aguardando aceitação',
      [TourStatus.WALKER_ON_THE_WAY]: 'Passeador a caminho',
      [TourStatus.IN_PROGRESS]: 'Em andamento',
      [TourStatus.FINISHED]: 'Finalizado',
      [TourStatus.REFUSED]: 'Recusado',
    };

    const formatDate = (value: string | null): string => {
      if (!value) return '-';
      return new Date(value).toLocaleString('pt-BR', {
        timeZone: 'America/Sao_Paulo',
      });
    };

    for (const row of rows) {
      sheet.addRow({
        pet_name: row.pet_name,
        tutor_name: row.tutor_name,
        started_at: formatDate(row.started_at),
        finished_at: formatDate(row.finished_at),
        distance_meters:
          row.distance_meters != null ? parseFloat(row.distance_meters) : '-',
        total_time_seconds:
          row.total_time_seconds != null
            ? parseInt(row.total_time_seconds, 10)
            : '-',
        price: row.price != null ? parseFloat(row.price) : '-',
        status: statusLabels[row.status] ?? row.status,
      });
    }

    const arrayBuffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(arrayBuffer);
  }

  private resolveDateRange(query: GetReportsQueryDto): {
    startDate?: Date;
    endDate?: Date;
  } {
    if (query.period === 'week') {
      const now = new Date();

      const dayOfWeek = now.getDay();
      const diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;

      const startDate = new Date(now);
      startDate.setDate(now.getDate() + diffToMonday);
      startDate.setHours(0, 0, 0, 0);

      const endDate = new Date(startDate);
      endDate.setDate(startDate.getDate() + 6);
      endDate.setHours(23, 59, 59, 999);

      return { startDate, endDate };
    }

    if (query.period === 'month') {
      const now = new Date();

      const startDate = new Date(
        now.getFullYear(),
        now.getMonth(),
        1,
        0,
        0,
        0,
        0,
      );

      const endDate = new Date(
        now.getFullYear(),
        now.getMonth() + 1,
        0,
        23,
        59,
        59,
        999,
      );

      return { startDate, endDate };
    }

    if (query.startDate && query.endDate) {
      const startDate = new Date(query.startDate);
      startDate.setHours(0, 0, 0, 0);

      const endDate = new Date(query.endDate);
      endDate.setHours(23, 59, 59, 999);

      return { startDate, endDate };
    }

    return {};
  }
}
