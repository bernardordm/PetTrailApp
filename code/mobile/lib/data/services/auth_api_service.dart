import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_trail/config/app_config.dart';

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri('/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(_extractErrorMessage(body, fallback: 'Falha ao fazer login.'));
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client
        .post(
          _uri('/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'role': role,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _parseJson(response.body);
    throw Exception(_extractErrorMessage(body, fallback: 'Falha ao criar conta.'));
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'message': decoded.toString()};
    } catch (_) {
      return {'message': body};
    }
  }

  String _extractErrorMessage(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
    return fallback;
  }
}
