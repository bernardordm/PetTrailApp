import 'package:pet_trail/data/services/auth_api_service.dart';
import 'package:pet_trail/domain/models/auth_user.dart';
import 'package:pet_trail/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api);

  final AuthApiService _api;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.login(email: email, password: password);
    return AuthUser(
      identifier: result['identifier']?.toString() ?? '',
      name: result['name']?.toString() ?? '',
      email: result['email']?.toString() ?? email,
      role: result['role']?.toString() ?? '',
      accessToken: result['accessToken']?.toString() ?? '',
    );
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return _api.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }
}
