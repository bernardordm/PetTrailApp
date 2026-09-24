import 'dart:typed_data';

import 'package:pet_trail/domain/models/profile_data.dart';

abstract class ProfileRepository {
  Future<ProfileData> fetchTutorProfile({
    required String identifier,
    required String accessToken,
  });

  Future<ProfileData> fetchWalkerProfile({
    required String identifier,
    required String accessToken,
  });

  Future<void> updateTutorProfile({
    required String identifier,
    required String accessToken,
    required ProfileData data,
  });

  Future<void> updateWalkerProfile({
    required String identifier,
    required String accessToken,
    required ProfileData data,
  });

  Future<String> uploadPhoto({
    required String role,
    required String identifier,
    required String accessToken,
    required Uint8List bytes,
    required String mimeType,
  });
}
