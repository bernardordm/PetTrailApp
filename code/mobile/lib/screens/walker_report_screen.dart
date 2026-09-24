import 'package:flutter/material.dart';
import 'package:pet_trail/domain/models/walker_report.dart';
import 'package:pet_trail/services/report_api_service.dart';

class WalkerReportScreen extends StatefulWidget {
  const WalkerReportScreen({super.key, required this.accessToken});

  final String accessToken;

  @override
  State<WalkerReportScreen> createState() => _WalkerReportScreenState();
}

class _WalkerReportScreenState extends State<WalkerReportScreen> {
  final _reportService = ReportApiService();

  WalkerReport? _report;

  bool _loading = true;

  String _selectedFilter = 'week';

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    setState(() => _loading = true);

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
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);

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
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
