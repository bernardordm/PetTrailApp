import { Controller, Get, Query, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { JwtAuthGuard } from '../../auth/jwt/jwt.auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { IAuthenticatedUser } from '../../auth/interfaces/auth.interface';
import type { WalkerReportMetrics } from '../services/reports.service';
import { ReportsService } from '../services/reports.service';
import { GetReportsQueryDto } from '../dtos/get-reports-query.dto';

@UseGuards(JwtAuthGuard)
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get()
  async getReports(
    @CurrentUser() user: IAuthenticatedUser,
    @Query() query: GetReportsQueryDto,
  ): Promise<WalkerReportMetrics> {
    return this.reportsService.getWalkerReport(user.identifier, query);
  }

  @Get('export')
  async exportTours(
    @CurrentUser() user: IAuthenticatedUser,
    @Query() query: GetReportsQueryDto,
    @Res() res: Response,
  ): Promise<void> {
    const buffer = await this.reportsService.exportWalkerToursXlsx(
      user.identifier,
      query,
    );

    const filename = `passeios-${new Date().toISOString().slice(0, 10)}.xlsx`;

    res.set({
      'Content-Type':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Content-Length': buffer.length,
    });

    res.end(buffer);
  }
}
