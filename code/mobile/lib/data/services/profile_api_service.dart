import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/domain/models/profile_data.dart';

class ProfileApiService {
  ProfileApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<ProfileData> fetchTutorProfile({
    required String identifier,
    required String accessToken,
  }) async {
    final response = await _client.get(
      _uri('/tutors/$identifier'),
      headers: _headers(accessToken),
    );
    final body = _parseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ProfileData(
        address: body['address']?.toString(),
        phone: body['phone']?.toString(),
        latitude: _asDouble(body['latitude']),
        longitude: _asDouble(body['longitude']),
        photoUrl: body['photo_url']?.toString(),
      );
    }
    throw Exception(_extractErrorMessage(body, fallback: 'Falha ao carregar perfil.'));
  }

  Future<ProfileData> fetchWalkerProfile({
    required String identifier,
    required String accessToken,
  }) async {
    final response = await _client.get(
      _uri('/walkers/$identifier'),
      headers: _headers(accessToken),
    );
    final body = _parseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ProfileData(
        phone: body['phone']?.toString(),
        document: body['document']?.toString(),
        walkPrice: _asDouble(body['walkPrice']),
        available: body['available'] is bool ? body['available'] as bool : null,
        averageRideTime: _asInt(body['averageRideTime']),
        averageRating: _asDouble(body['averageRating']),
        latitude: _asDouble(body['latitude']),
        longitude: _asDouble(body['longitude']),
        photoUrl: body['photo_url']?.toString(),
      );
    }
    throw Exception(_extractErrorMessage(body, fallback: 'Falha ao carregar perfil.'));
  }

  Future<void> updateTutorProfile({
    required String identifier,
    required String accessToken,
    required ProfileData data,
  }) async {
    final payload = <String, dynamic>{
      if (data.address != null) 'address': data.address,
      if (data.phone != null) 'phone': data.phone,
      if (data.latitude != null) 'latitude': data.latitude,
      if (data.longitude != null) 'longitude': data.longitude,
    };
    final response = await _client.patch(
      _uri('/tutors/$identifier'),
      headers: _headers(accessToken),
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = _parseJson(response.body);
    throw Exception(_extractErrorMessage(body, fallback: 'Falha ao salvar perfil.'));
  }

  Future<void> updateWalkerLocation({
    required String identifier,
    required String accessToken,
    required double latitude,
    required double longitude,
  }) async {
    await _client
        .patch(
          _uri('/walkers/location/$identifier'),
          headers: _headers(accessToken),
          body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
        )
        .timeout(const Duration(seconds: 15));
    // Falhas silenciosas — localização é best-effort
  }

  Future<void> updateWalkerAvailability({
    required String identifier,
    required String accessToken,
    required bool available,
  }) async {
    final response = await _client
        .patch(
          _uri('/walkers/available/$identifier'),
          headers: _headers(accessToken),
          body: jsonEncode({'available': available}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = _parseJson(response.body);
    throw Exception(_extractErrorMessage(body, fallback: 'Falha ao atualizar disponibilidade.'));
  }

  Future<void> updateWalkerProfile({
    required String identifier,
    required String accessToken,
    required ProfileData data,
  }) async {
    final payload = <String, dynamic>{
      if (data.phone != null) 'phone': data.phone,
      if (data.document != null) 'document': data.document,
      if (data.walkPrice != null) 'walkPrice': data.walkPrice,
      if (data.available != null) 'available': data.available,
      if (data.averageRideTime != null) 'averageRideTime': data.averageRideTime,
      if (data.latitude != null) 'latitude': data.latitude,
      if (data.longitude != null) 'longitude': data.longitude,
    };
    final response = await _client.patch(
      _uri('/walkers/$identifier'),
      headers: _headers(accessToken),
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = _parseJson(response.body);
    throw Exception(_extractErrorMessage(body, fallback: 'Falha ao salvar perfil.'));
  }

  Future<String> uploadPhoto({
    required String role,
    required String identifier,
    required String accessToken,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final normalizedMimeType = mimeType.trim().startsWith('image/')
        ? mimeType.trim().toLowerCase()
        : 'image/jpeg';
    final ext = normalizedMimeType.split('/').last;
    final contentTypeParts = normalizedMimeType.split('/');
    final request = http.MultipartRequest(
      'POST',
      _uri('/${role}s/$identifier/photo'),
    )
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: 'photo.$ext',
        contentType: MediaType(contentTypeParts.first, contentTypeParts.last),
      ));
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final body = _parseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return '/${role}s/$identifier/photo';
    }
    throw Exception(_extractErrorMessage(body, fallback: 'Falha ao enviar foto.'));
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

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return double.tryParse(value.toString())?.toInt();
  }
}
