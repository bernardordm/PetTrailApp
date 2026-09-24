import 'dart:typed_data';

import 'package:pet_trail/data/services/profile_api_service.dart';
import 'package:pet_trail/domain/models/profile_data.dart';
import 'package:pet_trail/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final ProfileApiService _api;

  @override
  Future<ProfileData> fetchTutorProfile({
    required String identifier,
    required String accessToken,
  }) {
    return _api.fetchTutorProfile(
      identifier: identifier,
      accessToken: accessToken,
    );
  }

  @override
  Future<ProfileData> fetchWalkerProfile({
    required String identifier,
    required String accessToken,
  }) {
    return _api.fetchWalkerProfile(
      identifier: identifier,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> updateTutorProfile({
    required String identifier,
    required String accessToken,
    required ProfileData data,
  }) {
    return _api.updateTutorProfile(
      identifier: identifier,
      accessToken: accessToken,
      data: data,
    );
  }

  @override
  Future<void> updateWalkerProfile({
    required String identifier,
    required String accessToken,
    required ProfileData data,
  }) {
    return _api.updateWalkerProfile(
      identifier: identifier,
      accessToken: accessToken,
      data: data,
    );
  }

  @override
  Future<String> uploadPhoto({
    required String role,
    required String identifier,
    required String accessToken,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return _api.uploadPhoto(
      role: role,
      identifier: identifier,
      accessToken: accessToken,
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
