import { Injectable, Logger } from '@nestjs/common';
import { Resend } from 'resend';
import { tourSummaryHtml } from './templates/tour-summary';

interface PathPoint {
  lat: number;
  lng: number;
}

interface SendTourSummaryParams {
  tutorEmail: string;
  tutorName: string;
  petName: string;
  walkerName: string;
  startedAt: Date | null;
  distanceMeters: number | null;
  totalTimeSeconds: number | null;
  price: number | null;
  rating: number | null;
  path: object | null;
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly resend: Resend | null;
  private readonly fromAddress: string;
  private readonly mapboxToken: string | null;

  constructor() {
    const apiKey = process.env.RESEND_API_KEY;
    this.resend = apiKey ? new Resend(apiKey) : null;
    this.fromAddress =
      process.env.EMAIL_FROM ?? 'PetTrail <onboarding@resend.dev>';
    this.mapboxToken = process.env.MAPBOX_ACCESS_TOKEN ?? null;

    if (!apiKey) {
      this.logger.warn(
        'RESEND_API_KEY não configurado — envio de emails desativado',
      );
    }
  }

  async sendTourSummary(params: SendTourSummaryParams): Promise<void> {
    this.logger.log(
      `[EMAIL] sendTourSummary chamado para ${params.tutorEmail} (pet: ${params.petName})`,
    );

    if (!this.resend) {
      this.logger.warn('[EMAIL] Abortado — RESEND_API_KEY não configurado');
      return;
    }

    try {
      const mapImageUrl = this.buildStaticMapUrl(params.path);
      this.logger.log(
        `[EMAIL] Mapa estático: ${mapImageUrl ? 'gerado ✓' : 'sem pontos suficientes, sem mapa'}`,
      );

      const html = tourSummaryHtml({
        tutorName: params.tutorName,
        petName: params.petName,
        walkerName: params.walkerName,
        date: this.formatDate(params.startedAt),
        distance: this.formatDistance(params.distanceMeters),
        duration: this.formatDuration(params.totalTimeSeconds),
        price: this.formatPrice(params.price),
        rating: this.formatRating(params.rating),
        mapImageUrl,
      });

      this.logger.log(
        `[EMAIL] Enviando para ${params.tutorEmail} via Resend (from: ${this.fromAddress})...`,
      );

      const { data, error } = await this.resend.emails.send({
        from: this.fromAddress,
        to: params.tutorEmail,
        subject: `Resumo do passeio de ${params.petName} — PetTrail`,
        html,
      });

      if (error) {
        this.logger.error(`[EMAIL] Falha no envio — ${JSON.stringify(error)}`);
      } else {
        this.logger.log(`[EMAIL] Enviado com sucesso ✓ id=${data?.id}`);
      }
    } catch (err) {
      this.logger.error('[EMAIL] Erro inesperado', err);
    }
  }

  private buildStaticMapUrl(path: object | null): string | null {
    if (!this.mapboxToken || !path) return null;

    const points = this.pathToPoints(path);
    if (points.length < 2) return null;

    const sampled = this.samplePoints(points, 80);
    const coordinates: [number, number][] = sampled.map((p) => [p.lng, p.lat]);

    const geojson = JSON.stringify({
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          geometry: { type: 'LineString', coordinates },
          properties: {
            stroke: '#ee5a52',
            'stroke-width': 4,
            'stroke-opacity': 0.95,
          },
        },
        {
          type: 'Feature',
          geometry: { type: 'Point', coordinates: coordinates[0] },
          properties: { 'marker-color': '#ee5a52', 'marker-size': 'medium' },
        },
        {
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: coordinates[coordinates.length - 1],
          },
          properties: { 'marker-color': '#ad413b', 'marker-size': 'medium' },
        },
      ],
    });

    const encoded = encodeURIComponent(geojson);
    return (
      `https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/` +
      `geojson(${encoded})/auto/600x320?padding=40&access_token=${this.mapboxToken}`
    );
  }

  private pathToPoints(path: object): PathPoint[] {
    const points: PathPoint[] = [];
    const record = path as Record<string, PathPoint>;
    const keys = Object.keys(record).sort((a, b) => Number(a) - Number(b));
    for (const key of keys) {
      const p = record[key];
      if (typeof p?.lat === 'number' && typeof p?.lng === 'number') {
        points.push({ lat: p.lat, lng: p.lng });
      }
    }
    return points;
  }

  private samplePoints(points: PathPoint[], max: number): PathPoint[] {
    if (points.length <= max) return points;
    const step = points.length / max;
    const result: PathPoint[] = [];
    for (let i = 0; i < max; i++) {
      result.push(points[Math.floor(i * step)]);
    }
    result.push(points[points.length - 1]);
    return result;
  }

  private formatDate(date: Date | null): string {
    if (!date) return '—';
    return date.toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      timeZone: 'America/Sao_Paulo',
    });
  }

  private formatDistance(meters: number | null): string {
    if (meters === null) return '—';
    if (meters < 1000) return `${Math.round(meters)} m`;
    return `${(meters / 1000).toFixed(2)} km`;
  }

  private formatDuration(seconds: number | null): string {
    if (seconds === null) return '—';
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) return `${h}h ${m}min`;
    if (m > 0) return `${m}min ${s}s`;
    return `${s}s`;
  }

  private formatPrice(price: number | null): string {
    if (price === null) return '—';
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(price);
  }

  private formatRating(rating: number | null): string {
    if (rating === null) return 'Pendente';
    const stars = '★'.repeat(rating) + '☆'.repeat(5 - rating);
    return `${stars} (${rating}/5)`;
  }
}
