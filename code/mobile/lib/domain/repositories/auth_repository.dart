import 'package:pet_trail/domain/models/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  });
}
