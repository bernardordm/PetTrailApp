import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/domain/models/pet.dart';
import 'package:pet_trail/domain/models/tour.dart';

class TourApiService {
  TourApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Uri _workerUri(String path) => Uri.parse('${AppConfig.workerBaseUrl}$path');

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Pet>> fetchPets({
    required String accessToken,
    required String tutorIdentifier,
  }) async {
    final response = await _client
        .get(
          _uri('/tutors/$tutorIdentifier/pets'),
          headers: _headers(accessToken),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Pet.fromJson)
            .toList();
      }
      return [];
    }
    throw Exception('Erro ao buscar pets');
  }

  Future<Uint8List?> fetchPetPhoto({
    required String accessToken,
    required String tutorIdentifier,
    required String petIdentifier,
  }) async {
    try {
      final response = await _client
          .get(
            _uri('/tutors/$tutorIdentifier/pets/$petIdentifier/photo'),
            headers: _headers(accessToken),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  Future<void> createTourRequest({
    required String accessToken,
    required String walkerIdentifier,
    required String tutorIdentifier,
    required String petIdentifier,
    required double tutorLatitude,
    required double tutorLongitude,
  }) async {
    final response = await _client
        .post(
          _uri('/tours/new'),
          headers: _headers(accessToken),
          body: jsonEncode({
            'walker_identifier': walkerIdentifier,
            'tutor_identifier': tutorIdentifier,
            'pet_identifier': petIdentifier,
            'tutor_latitude': tutorLatitude,
            'tutor_longitude': tutorLongitude,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao solicitar passeio');
    }
  }

  Future<void> confirmTour({
    required String accessToken,
    required String tourIdentifier,
    required bool accepted,
  }) async {
    final response = await _client
        .patch(
          _workerUri('/tours/$tourIdentifier/confirm'),
          headers: _headers(accessToken),
          body: jsonEncode({'accepted': accepted}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao confirmar passeio');
    }
  }

  Future<void> startTour({
    required String accessToken,
    required String tourIdentifier,
    required String confirmationCode,
  }) async {
    final response = await _client
        .patch(
          _workerUri('/tours/$tourIdentifier/start'),
          headers: _headers(accessToken),
          body: jsonEncode({'confirmation_code': confirmationCode}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao iniciar passeio');
    }
  }

  Future<void> syncActiveTour({
    required String accessToken,
    required String tourIdentifier,
  }) async {
    final response = await _client
        .post(
          _workerUri('/tours/$tourIdentifier/sync-active'),
          headers: _headers(accessToken),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao sincronizar passeio ativo');
    }
  }

  Future<void> clearTutorTourNotification({
    required String accessToken,
    required String identifier,
  }) async {
    final response = await _client
        .patch(_workerUri('/tours/$identifier/clear'), headers: _headers(accessToken))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao limpar notificação do passeio');
    }
  }

  Future<List<Tour>> fetchMyTours({required String accessToken}) async {
    final response = await _client
        .get(_workerUri('/tours/my'), headers: _headers(accessToken))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Tour.fromJson)
            .toList();
      }
      return [];
    }
    throw Exception('Erro ao buscar passeios');
  }

  Future<Tour> fetchTourById({
    required String accessToken,
    required String identifier,
  }) async {
    final response = await _client
        .get(_workerUri('/tours/$identifier'), headers: _headers(accessToken))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Tour.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Passeio não encontrado');
  }

  Future<Map<String, String>> generateTerminationCode({
    required String accessToken,
    required String tourIdentifier,
    required double distanceMeters,
    required int totalTimeSeconds,
    required Map<String, dynamic> path,
  }) async {
    final response = await _client
        .post(
          _workerUri('/tours/$tourIdentifier/generate-termination-code'),
          headers: _headers(accessToken),
          body: jsonEncode({
            'distance_meters': distanceMeters,
            'total_time_seconds': totalTimeSeconds,
            'path': path,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'qr_token': decoded['qr_token'] as String,
        'expires_at': decoded['expires_at'] as String,
      };
    }
    throw Exception('Erro ao gerar código de encerramento');
  }

  Future<Map<String, dynamic>> finishTour({
    required String accessToken,
    required String tourIdentifier,
    required String qrToken,
  }) async {
    final response = await _client
        .patch(
          _workerUri('/tours/$tourIdentifier/finish'),
          headers: _headers(accessToken),
          body: jsonEncode({'qr_token': qrToken}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    final message = body is Map
        ? body['message'] ?? 'Erro ao finalizar passeio'
        : 'Erro ao finalizar passeio';
    throw Exception(message);
  }

  Future<void> sendReview({
    required String accessToken,
    required String tourIdentifier,
    required int rating,
  }) async {
    final response = await _client
        .patch(
          _workerUri('/tours/$tourIdentifier/rate'),
          headers: _headers(accessToken),
          body: jsonEncode({'rating': rating}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao enviar avaliação');
    }
  }

}
