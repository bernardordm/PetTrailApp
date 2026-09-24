import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:pet_trail/config/app_config.dart';

class PetService {
  final String accessToken;

  PetService(this.accessToken);

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<List<dynamic>> getPets(String tutorId) async {
    final response = await http.get(
      _uri('/tutors/$tutorId/pets'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Erro ao buscar pets: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> createPet(
    String tutorId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri('/tutors/$tutorId/pets'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Erro ao criar pet: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> updatePet(
    String tutorId,
    String petId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      _uri('/tutors/$tutorId/pets/$petId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao atualizar pet: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> deletePet(String tutorId, String petId) async {
    final response = await http.delete(
      _uri('/tutors/$tutorId/pets/$petId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao deletar pet: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> uploadPhoto(
    String tutorId,
    String petId,
    Uint8List bytes, {
    String? fileName,
  }) async {
    final mimeType = lookupMimeType(fileName ?? 'pet.jpg', headerBytes: bytes);
    final mediaType = mimeType != null
        ? MediaType.parse(mimeType)
        : MediaType('image', 'jpeg');

    final request = http.MultipartRequest(
      'POST',
      _uri('/tutors/$tutorId/pets/$petId/photo'),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: fileName ?? 'pet.jpg',
        contentType: mediaType,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 201 &&
        response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        'Erro ao enviar foto: ${response.statusCode} - $responseBody',
      );
    }
  }
}
