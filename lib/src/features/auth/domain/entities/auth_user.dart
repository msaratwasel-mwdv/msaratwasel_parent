class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.role,
    required this.accessToken,
    this.refreshToken,
  });

  final String id;
  final String name;
  final String role;
  final String accessToken;
  final String? refreshToken;
}
