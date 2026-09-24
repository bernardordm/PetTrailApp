import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/domain/models/walker_pin_info.dart';

class WalkerApiService {
  WalkerApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? params]) {
    final base = Uri.parse('${AppConfig.apiBaseUrl}$path');
    return params != null ? base.replace(queryParameters: params) : base;
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<WalkerPinInfo> findOneForPin({
    required String accessToken,
    required String identifier,
  }) async {
    final response = await _client
        .get(
          _uri('/walkers/pin/$identifier'),
          headers: _headers(accessToken),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return WalkerPinInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }
    throw Exception('Erro ao buscar dados do passeador');
  }
}
