import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/domain/models/tour.dart';
import 'package:pet_trail/utils/mapbox_walk_path_snap.dart';
import 'package:pet_trail/screens/chat_screen.dart';
import 'package:pet_trail/presentation/controllers/chat_controller.dart';

class TourDetailScreen extends StatefulWidget {
  const TourDetailScreen({
    super.key,
    required this.tour,
    required this.isWalker,
    required this.accessToken,
  });

  final Tour tour;
  final bool isWalker;
  final String accessToken;

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  ChatController? _chatController;

  @override
  void dispose() {
    _chatController?.dispose();
    super.dispose();
  }

  bool get _isChatActive =>
      widget.tour.status == 'WALKER_ON_THE_WAY' ||
      widget.tour.status == 'IN_PROGRESS';

  String get _currentUserId =>
      widget.isWalker ? widget.tour.walkerIdentifier : widget.tour.tutorIdentifier;

  String get _counterpartName {
    if (widget.isWalker) return widget.tour.tutorName ?? 'Tutor';
    return widget.tour.walkerName ?? 'Passeador';
  }

  void _openChat(BuildContext context) {
    final controller = _chatController ??= ChatController(
      chatBaseUrl: AppConfig.chatBaseUrl,
      token: widget.accessToken,
      tourId: widget.tour.identifier,
      currentUserId: _currentUserId,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          controller: controller,
          currentUserId: _currentUserId,
          counterpartName: _counterpartName,
        ),
      ),
    );
  }

  String _tourTitle() {
    final d = widget.tour.createdAt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return 'Passeio: $day/$month';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y\n$h:$min';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '$m min';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _statusLabel(String status) => switch (status) {
    'WAITING_ACCEPTANCE' => 'Aguardando aceite',
    'WALKER_ON_THE_WAY' => 'Á caminho',
    'IN_PROGRESS' => 'Em andamento',
    'FINISHED' => 'Concluído',
    'REFUSED' => 'Recusado',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'WAITING_ACCEPTANCE' => Colors.orange,
    'WALKER_ON_THE_WAY' => Colors.blue,
    'IN_PROGRESS' => Colors.green,
    'FINISHED' => Colors.teal,
    'REFUSED' => Colors.red,
    _ => Colors.grey,
  };

  IconData _statusIcon(String status) => switch (status) {
    'WAITING_ACCEPTANCE' => Icons.hourglass_empty_rounded,
    'WALKER_ON_THE_WAY' => Icons.directions_run_rounded,
    'IN_PROGRESS' => Icons.play_arrow_rounded,
    'FINISHED' => Icons.check_circle_rounded,
    'REFUSED' => Icons.cancel_rounded,
    _ => Icons.help_outline_rounded,
  };

  static List<mb.Position> _parsePathPoints(Map<String, dynamic>? path) {
    if (path == null || path.isEmpty) return [];
    final points = <mb.Position>[];
    final keys = path.keys.toList()
      ..sort((a, b) {
        final ia = int.tryParse(a) ?? 0;
        final ib = int.tryParse(b) ?? 0;
        return ia.compareTo(ib);
      });
    for (final key in keys) {
      final point = path[key];
      if (point is Map) {
        final lat = (point['lat'] as num?)?.toDouble();
        final lng = (point['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          points.add(mb.Position(lng, lat));
        }
      }
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final pathPoints = _parsePathPoints(widget.tour.path);

    return Scaffold(
      appBar: AppBar(
        title: Text(_tourTitle()),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isChatActive)
            IconButton(
              onPressed: () => _openChat(context),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Abrir chat',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título seção ──
            Text(
              'Informações Gerais',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // ── Pet + Tutor/Passeador ──
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.pets_rounded,
                    label: 'Pet',
                    value: widget.tour.petName ?? '—',
                    photoUrl:
                        '${AppConfig.apiBaseUrl}/tutors/${widget.tour.tutorIdentifier}/pets/${widget.tour.petIdentifier}/photo',
                    accessToken: widget.accessToken,
                    cs: cs,
                    tt: tt,
                  ),
                ),
                const SizedBox(width: 12),
                if (!widget.isWalker)
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.directions_walk_rounded,
                      label: 'Passeador',
                      value: widget.tour.walkerName ?? '—',
                      photoUrl:
                          '${AppConfig.apiBaseUrl}/walkers/${widget.tour.walkerIdentifier}/photo',
                      accessToken: widget.accessToken,
                      cs: cs,
                      tt: tt,
                    ),
                  )
                else
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.person_outline_rounded,
                      label: 'Tutor',
                      value: widget.tour.tutorName ?? '—',
                      photoUrl:
                          '${AppConfig.apiBaseUrl}/tutors/${widget.tour.tutorIdentifier}/photo',
                      accessToken: widget.accessToken,
                      cs: cs,
                      tt: tt,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Solicitado em + Valor (data/hora precisa de mais largura em telas estreitas) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _InfoCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Solicitado em',
                    value: _formatDate(widget.tour.createdAt),
                    cs: cs,
                    tt: tt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _InfoCard(
                    icon: Icons.attach_money_rounded,
                    label: 'Valor',
                    value: widget.tour.price != null
                        ? 'R\$ ${widget.tour.price!.toStringAsFixed(2)}'
                        : '—',
                    cs: cs,
                    tt: tt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Status (+ código de confirmação se a caminho / avaliação se concluído) ──
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: _statusIcon(widget.tour.status),
                    label: 'Status',
                    value: _statusLabel(widget.tour.status),
                    iconColor: _statusColor(widget.tour.status),
                    cs: cs,
                    tt: tt,
                  ),
                ),
                if (!widget.isWalker && widget.tour.status == 'WALKER_ON_THE_WAY') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.lock_outline_rounded,
                      label: 'Código de confirmação',
                      value: widget.tour.confirmationCode ?? '—',
                      iconColor: Colors.orange,
                      cs: cs,
                      tt: tt,
                    ),
                  ),
                ],
                if (widget.tour.status == 'FINISHED' && widget.tour.rating != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.star_rounded,
                      label: 'Avaliação',
                      value: '${widget.tour.rating} / 5',
                      iconColor: Colors.amber,
                      cs: cs,
                      tt: tt,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 6),

            // ── Walk stats ──
            Text(
              'Informações do Passeio',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Início',
                    value: widget.tour.startedAt != null
                        ? _formatTime(widget.tour.startedAt!)
                        : '—',
                    color: Colors.green,
                    cs: cs,
                    tt: tt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.stop_circle_outlined,
                    label: 'Fim',
                    value: widget.tour.finishedAt != null
                        ? _formatTime(widget.tour.finishedAt!)
                        : '—',
                    color: Colors.red,
                    cs: cs,
                    tt: tt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_outlined,
                    label: 'Duração',
                    value: widget.tour.totalTimeSeconds != null
                        ? _formatDuration(widget.tour.totalTimeSeconds!)
                        : '—',
                    color: Colors.blue,
                    cs: cs,
                    tt: tt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.route_rounded,
                    label: 'Distância',
                    value: widget.tour.distanceMeters != null
                        ? _formatDistance(widget.tour.distanceMeters!)
                        : '—',
                    color: Colors.purple,
                    cs: cs,
                    tt: tt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Mapa do percurso ──
            Text(
              'Percurso',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 220,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: pathPoints.length >= 2
                  ? _TourRouteMap(points: pathPoints)
                  : _NoRouteWidget(cs: cs, tt: tt),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Info card (pet / tutor / walker) ──────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
    this.iconColor,
    this.photoUrl,
    this.accessToken,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;
  final Color? iconColor;
  final String? photoUrl;
  final String? accessToken;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (photoUrl != null && accessToken != null)
            ClipOval(
              child: SizedBox(
                width: 32,
                height: 32,
                child: Image.network(
                  photoUrl!,
                  headers: {'Authorization': 'Bearer $accessToken'},
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.surfaceContainerHighest,
                    child: Icon(icon, size: 16, color: iconColor ?? cs.primary),
                  ),
                ),
              ),
            )
          else
            Icon(icon, size: 18, color: iconColor ?? cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  softWrap: true,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
    required this.tt,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mapa real do percurso ─────────────────────────────────────────────────────

class _TourRouteMap extends StatefulWidget {
  const _TourRouteMap({required this.points});

  final List<mb.Position> points;

  @override
  State<_TourRouteMap> createState() => _TourRouteMapState();
}

class _TourRouteMapState extends State<_TourRouteMap> {
  mb.PointAnnotationManager? _pointManager;
  mb.PolylineAnnotationManager? _polylineManager;

  void _onMapCreated(mb.MapboxMap mapboxMap) async {
    final styleUri = AppConfig.mapboxStyleUriForBrightness(
      Theme.of(context).brightness == Brightness.dark,
    );
    await mapboxMap.style.setStyleURI(styleUri);
    final start = widget.points.first;
    final end = widget.points.last;
    await mapboxMap.setCamera(
      mb.CameraOptions(
        center: mb.Point(
          coordinates: mb.Position(
            (start.lng + end.lng) / 2,
            (start.lat + end.lat) / 2,
          ),
        ),
        zoom: 15,
      ),
    );

    var routeCoords = widget.points;
    if (widget.points.length >= 2 && AppConfig.hasMapboxAccessToken) {
      final rawLatLng = widget.points
          .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
          .toList();
      final snapped = await fetchMapboxWalkingMatchedPath(
        rawPoints: rawLatLng,
        mapboxAccessToken: AppConfig.mapboxAccessToken,
      );
      if (snapped != null && snapped.length >= 2) {
        routeCoords = snapped
            .map((e) => mb.Position(e.longitude, e.latitude))
            .toList();
      }
    }
    if (!mounted) return;

    _polylineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();
    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();
    await _polylineManager?.create(
      mb.PolylineAnnotationOptions(
        geometry: mb.LineString(coordinates: routeCoords),
        lineColor: const Color(0xFF3D5AFE).toARGB32(),
        lineWidth: 4,
      ),
    );
    await _pointManager?.create(
      mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: start),
      ),
    );
    await _pointManager?.create(
      mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasMapboxAccessToken) {
      return const Center(
        child: Text('Configure MAPBOX_ACCESS_TOKEN para exibir o mapa.'),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return mb.MapWidget(
      key: ValueKey('tour-detail-mapbox-$isDark'),
      onMapCreated: _onMapCreated,
      textureView: true,
    );
  }
}

// ── Placeholder quando não há percurso ───────────────────────────────────────

class _NoRouteWidget extends StatelessWidget {
  const _NoRouteWidget({required this.cs, required this.tt});

  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, size: 36, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'Percurso não disponível',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
