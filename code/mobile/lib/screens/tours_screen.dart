import 'package:flutter/material.dart';
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/data/services/tour_api_service.dart';
import 'package:pet_trail/domain/models/tour.dart';
import 'package:pet_trail/screens/tour_detail_screen.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({
    super.key,
    required this.identifier,
    required this.role,
    required this.accessToken,
    this.embeddedInShell = false,
  });

  final String identifier;
  final String role;
  final String accessToken;

  /// Conteúdo sem [Scaffold] próprio (aba do [MainShellScreen]).
  final bool embeddedInShell;

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  final _tourService = TourApiService();

  bool _loading = true;
  String? _error;
  List<Tour> _tours = [];

  bool get _isWalker => widget.role == 'walker';

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tours = await _tourService.fetchMyTours(
        accessToken: widget.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _tours = tours;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.embeddedInShell) {
      return ColoredBox(
        color: cs.surface,
        child: _buildBody(cs),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Passeios'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: cs.secondary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _fetchTours,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_tours.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_walk_rounded,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum passeio encontrado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTours,
      color: cs.secondary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _tours.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _TourCard(
          tour: _tours[index],
          isWalker: _isWalker,
          accessToken: widget.accessToken,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TourDetailScreen(
                tour: _tours[index],
                isWalker: _isWalker,
                accessToken: widget.accessToken,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.tour,
    required this.isWalker,
    required this.accessToken,
    required this.onTap,
  });

  final Tour tour;
  final bool isWalker;
  final String accessToken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dt = tour.createdAt.toLocal();
    final formattedDate =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final counterpartLabel = isWalker ? 'Tutor' : 'Passeador';
    final counterpartName =
        isWalker ? (tour.tutorName ?? '—') : (tour.walkerName ?? '—');

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(
                    '${AppConfig.apiBaseUrl}/tutors/${tour.tutorIdentifier}/pets/${tour.petIdentifier}/photo',
                    headers: {'Authorization': 'Bearer $accessToken'},
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.pets, size: 28, color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tour.petName ?? 'Pet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _StatusChip(status: tour.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: counterpartLabel,
                      value: counterpartName,
                      cs: cs,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Data',
                      value: formattedDate,
                      cs: cs,
                    ),
                    if (tour.price != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.attach_money_rounded,
                        label: 'Valor',
                        value: 'R\$ ${tour.price!.toStringAsFixed(2)}',
                        cs: cs,
                      ),
                    ],
                    if (!isWalker && tour.status == 'WALKER_ON_THE_WAY') ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Código',
                        value: tour.confirmationCode ?? '—',
                        cs: cs,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'WAITING_ACCEPTANCE' => ('Aguardando', Colors.orange),
      'WALKER_ON_THE_WAY' => ('A caminho', Colors.blue),
      'IN_PROGRESS' => ('Em andamento', Colors.green),
      'FINISHED' => ('Concluído', Colors.teal),
      'REFUSED' => ('Recusado', Colors.red),
      _ => (status, Colors.grey),
    };

    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
