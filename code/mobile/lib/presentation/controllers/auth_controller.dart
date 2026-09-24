import 'package:flutter/foundation.dart';
import 'package:pet_trail/domain/models/auth_user.dart';
import 'package:pet_trail/domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  bool _isDisposed = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? consumeError() {
    final value = _errorMessage;
    _errorMessage = null;
    return value;
  }

  void _setSubmitting(bool value) {
    if (_isDisposed) return;
    _isSubmitting = value;
    notifyListeners();
  }

  void _setError(String? value) {
    if (_isDisposed) return;
    _errorMessage = value;
    notifyListeners();
  }

  Future<AuthUser?> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _setError('Preencha e-mail e senha.');
      return null;
    }

    _setSubmitting(true);
    _setError(null);
    try {
      return await _repository.login(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      _setError('Preencha todos os campos.');
      return false;
    }

    _setSubmitting(true);
    _setError(null);
    try {
      await _repository.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role,
      );
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setSubmitting(false);
    }
  }
}
