import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pet_trail/domain/models/walker_report.dart';
import 'package:pet_trail/services/report_api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.accessToken});

  final String accessToken;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportService = ReportApiService();

  WalkerReport? _report;

  bool _loading = true;
  String? _errorMessage;

  String _selectedFilter = 'month';
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _report = null;
    });

    try {
      final report = await _reportService.getMonthlyReport(
        accessToken: widget.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _report = report;
        _selectedFilter = 'month';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _report = null;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadWeek() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _report = null;
    });

    try {
      final report = await _reportService.getWeeklyReport(
        accessToken: widget.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _report = report;
        _selectedFilter = 'week';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _report = null;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange,
    );

    if (range == null) return;

    await _loadCustomRange(range);
  }

  Future<void> _loadCustomRange(DateTimeRange range) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _report = null;
      _customRange = range;
    });

    try {
      final report = await _reportService.getCustomReport(
        accessToken: widget.accessToken,
        startDate: range.start,
        endDate: range.end,
      );

      if (!mounted) return;

      setState(() {
        _report = report;
        _selectedFilter = 'custom';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _report = null;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _reloadCurrentFilter() async {
    if (_selectedFilter == 'week') {
      await _loadWeek();
      return;
    }

    if (_selectedFilter == 'custom') {
      if (_customRange != null) {
        await _loadCustomRange(_customRange!);
      } else {
        await _pickCustomRange();
      }
      return;
    }

    await _loadMonth();
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  String _formatDistance(double value) {
    if (value < 1000) {
      return '${value.toStringAsFixed(0)} m';
    }

    return '${(value / 1000).toStringAsFixed(2)} km';
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }

    if (minutes > 0) {
      return '${minutes}min ${remainingSeconds}s';
    }

    return '${remainingSeconds}s';
  }

  String _formatPeriodLabel() {
    if (_selectedFilter == 'month') {
      return 'Mês atual';
    }

    if (_selectedFilter == 'week') {
      return 'Semana atual';
    }

    if (_customRange != null) {
      final start = _customRange!.start;
      final end = _customRange!.end;

      return '${start.day.toString().padLeft(2, '0')}/'
          '${start.month.toString().padLeft(2, '0')}/'
          '${start.year} até '
          '${end.day.toString().padLeft(2, '0')}/'
          '${end.month.toString().padLeft(2, '0')}/'
          '${end.year}';
    }

    return 'Personalizado';
  }

  bool _hasAnyData(WalkerReport report) {
    return report.totalEarnings > 0 ||
        report.totalDistanceMeters > 0 ||
        report.totalTimeSeconds > 0 ||
        report.completionRate > 0 ||
        report.averageTimeSeconds > 0 ||
        report.averageDistanceMeters > 0 ||
        report.averageRating > 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _reloadCurrentFilter,
      );
    }

    if (_report == null) {
      return _EmptyState(onRetry: _reloadCurrentFilter);
    }

    final report = _report!;
    final hasData = _hasAnyData(report);

    return RefreshIndicator(
      onRefresh: _reloadCurrentFilter,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(
              periodLabel: _formatPeriodLabel(),
              totalEarnings: _formatMoney(report.totalEarnings),
              completionRate: report.completionRate,
            ),

            const SizedBox(height: 14),

            _FilterChips(
              selectedFilter: _selectedFilter,
              onMonth: _loadMonth,
              onWeek: _loadWeek,
              onCustom: _pickCustomRange,
            ),

            const SizedBox(height: 16),

            if (!hasData) _NoDataWarning(periodLabel: _formatPeriodLabel()),

            if (!hasData) const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.28,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MetricTile(
                  title: 'Ganhos',
                  value: _formatMoney(report.totalEarnings),
                  icon: Icons.attach_money_rounded,
                ),
                _MetricTile(
                  title: 'Distância',
                  value: _formatDistance(report.totalDistanceMeters),
                  icon: Icons.route_rounded,
                ),
                _MetricTile(
                  title: 'Tempo total',
                  value: _formatTime(report.totalTimeSeconds),
                  icon: Icons.timer_rounded,
                ),
                _MetricTile(
                  title: 'Avaliação',
                  value: report.averageRating > 0
                      ? report.averageRating.toStringAsFixed(1)
                      : '0.0',
                  icon: Icons.star_rounded,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _ChartCard(
              title: 'Conclusão dos passeios',
              subtitle:
                  '${report.completionRate.toStringAsFixed(1)}% concluídos',
              child: _CompletionDonutChart(
                completionRate: report.completionRate,
              ),
            ),

            const SizedBox(height: 16),

            _ChartCard(
              title: 'Resumo visual',
              subtitle: 'Comparativo proporcional das principais métricas',
              child: _SummaryBarChart(report: report),
            ),

            const SizedBox(height: 16),

            _AveragesSection(
              averageTime: _formatTime(report.averageTimeSeconds.round()),
              averageDistance: _formatDistance(report.averageDistanceMeters),
              averageRating: report.averageRating.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.periodLabel,
    required this.totalEarnings,
    required this.completionRate,
  });

  final String periodLabel;
  final String totalEarnings;
  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSecondaryContainer.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalEarnings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ganhos no período',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSecondaryContainer.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.78),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${completionRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: cs.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedFilter,
    required this.onMonth,
    required this.onWeek,
    required this.onCustom,
  });

  final String selectedFilter;
  final VoidCallback onMonth;
  final VoidCallback onWeek;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Mês'),
          selected: selectedFilter == 'month',
          onSelected: (_) => onMonth(),
        ),
        ChoiceChip(
          label: const Text('Semana'),
          selected: selectedFilter == 'week',
          onSelected: (_) => onWeek(),
        ),
        ChoiceChip(
          label: const Text('Personalizado'),
          selected: selectedFilter == 'custom',
          onSelected: (_) => onCustom(),
        ),
      ],
    );
  }
}

class _NoDataWarning extends StatelessWidget {
  const _NoDataWarning({required this.periodLabel});

  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhuma métrica encontrada para $periodLabel. '
              'Tente selecionar um período personalizado que inclua passeios concluídos.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.secondaryContainer,
            child: Icon(icon, color: cs.onSecondaryContainer, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 190, child: child),
        ],
      ),
    );
  }
}

class _CompletionDonutChart extends StatelessWidget {
  const _CompletionDonutChart({required this.completionRate});

  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final completed = completionRate.clamp(0, 100).toDouble();
    final remaining = max(0.0, 100 - completed);

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            startDegreeOffset: -90,
            centerSpaceRadius: 56,
            sectionsSpace: 4,
            sections: [
              PieChartSectionData(
                value: completed == 0 ? 0.01 : completed,
                title: '',
                radius: 28,
                color: cs.secondary,
              ),
              PieChartSectionData(
                value: remaining == 0 ? 0.01 : remaining,
                title: '',
                radius: 28,
                color: cs.surfaceContainerHighest,
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${completed.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.secondary,
              ),
            ),
            Text(
              'concluídos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryBarChart extends StatelessWidget {
  const _SummaryBarChart({required this.report});

  final WalkerReport report;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final earnings = report.totalEarnings;
    final distanceKm = report.totalDistanceMeters / 1000;
    final timeMinutes = report.totalTimeSeconds / 60;
    final ratingScaled = report.averageRating * 20;

    final rawValues = <double>[earnings, distanceKm, timeMinutes, ratingScaled];

    final maxValue = rawValues.reduce(max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final normalized = rawValues.map((value) {
      if (value <= 0) return 0.0;
      return (value / safeMax) * 100;
    }).toList();

    return BarChart(
      BarChartData(
        maxY: 110,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final labels = ['R\$', 'Km', 'Min', 'Nota'];
                final index = value.toInt();

                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(normalized.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: normalized[index],
                width: 22,
                borderRadius: BorderRadius.circular(8),
                color: cs.secondary,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: cs.surfaceContainerHighest,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AveragesSection extends StatelessWidget {
  const _AveragesSection({
    required this.averageTime,
    required this.averageDistance,
    required this.averageRating,
  });

  final String averageTime;
  final String averageDistance;
  final String averageRating;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Médias do período',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _AverageRow(
            icon: Icons.av_timer_rounded,
            label: 'Tempo médio',
            value: averageTime,
          ),
          const Divider(height: 22),
          _AverageRow(
            icon: Icons.timeline_rounded,
            label: 'Distância média',
            value: averageDistance,
          ),
          const Divider(height: 22),
          _AverageRow(
            icon: Icons.star_rounded,
            label: 'Avaliação média',
            value: averageRating,
          ),
        ],
      ),
    );
  }
}

class _AverageRow extends StatelessWidget {
  const _AverageRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: cs.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Erro ao carregar relatório',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_chart_outlined_rounded,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum relatório encontrado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foram encontradas métricas para o período selecionado.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
