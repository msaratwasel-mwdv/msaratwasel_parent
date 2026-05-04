import '../../domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({
    required String civilId,
    required String password,
  });

  Future<void> requestPasswordReset({required String phoneOrUsername});
}
