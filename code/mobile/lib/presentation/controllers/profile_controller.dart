import 'package:flutter/foundation.dart';
import 'package:pet_trail/domain/models/profile_data.dart';
import 'package:pet_trail/domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? consumeError() {
    final value = _errorMessage;
    _errorMessage = null;
    return value;
  }

  Future<ProfileData?> load({
    required String role,
    required String identifier,
    required String accessToken,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (role == 'walker') {
        return await _repository.fetchWalkerProfile(
          identifier: identifier,
          accessToken: accessToken,
        );
      }
      return await _repository.fetchTutorProfile(
        identifier: identifier,
        accessToken: accessToken,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    required String role,
    required String identifier,
    required String accessToken,
    required ProfileData data,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      if (role == 'walker') {
        await _repository.updateWalkerProfile(
          identifier: identifier,
          accessToken: accessToken,
          data: data,
        );
      } else {
        await _repository.updateTutorProfile(
          identifier: identifier,
          accessToken: accessToken,
          data: data,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Retorna a nova photoUrl em caso de sucesso, ou null em falha.
  Future<String?> uploadPhoto({
    required String role,
    required String identifier,
    required String accessToken,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    _isUploadingPhoto = true;
    notifyListeners();
    try {
      return await _repository.uploadPhoto(
        role: role,
        identifier: identifier,
        accessToken: accessToken,
        bytes: bytes,
        mimeType: mimeType,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }
}
