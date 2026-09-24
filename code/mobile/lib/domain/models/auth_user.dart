class AuthUser {
  const AuthUser({
    required this.identifier,
    required this.name,
    required this.email,
    required this.role,
    required this.accessToken,
  });

  final String identifier;
  final String name;
  final String email;
  final String role; // tutor | walker
  final String accessToken;
}
