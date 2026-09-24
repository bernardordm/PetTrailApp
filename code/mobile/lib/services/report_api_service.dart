import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/domain/models/walker_report.dart';

class ReportApiService {
  ReportApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? params]) {
    final base = Uri.parse('${AppConfig.apiBaseUrl}$path');
    return params != null ? base.replace(queryParameters: params) : base;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<WalkerReport> _getReport({
    required String accessToken,
    required Map<String, String> params,
  }) async {
    final uri = _uri('/reports', params);

    print('CHAMANDO REPORTS: $uri');

    final response = await _client
        .get(uri, headers: _headers(accessToken))
        .timeout(const Duration(seconds: 20));

    print('STATUS REPORTS: ${response.statusCode}');
    print('BODY REPORTS: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao buscar relatório: ${response.statusCode} - ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inesperada do relatório: ${response.body}');
    }

    return WalkerReport.fromJson(decoded);
  }

  Future<WalkerReport> getWeeklyReport({required String accessToken}) {
    return _getReport(accessToken: accessToken, params: {'period': 'week'});
  }

  Future<WalkerReport> getMonthlyReport({required String accessToken}) {
    return _getReport(accessToken: accessToken, params: {'period': 'month'});
  }

  Future<WalkerReport> getCustomReport({
    required String accessToken,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _getReport(
      accessToken: accessToken,
      params: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
  }
}
