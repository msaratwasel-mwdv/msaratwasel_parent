import '../../domain/entities/auth_user.dart';

abstract class AuthRepository {
  /// TODO: call LOGIN_API and return tokens + user role.
  Future<AuthUser> login({
    required String civilId,
    required String phoneNumber,
  });

  /// TODO: trigger forgot-password flow.
  Future<void> requestPasswordReset({required String phoneOrUsername});
}
