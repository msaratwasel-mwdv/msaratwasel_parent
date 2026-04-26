import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/auth/domain/entities/auth_user.dart';
import './auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;

  AuthRepositoryImpl({required this.dio});

  @override
  Future<AuthUser> login({
    required String civilId,
    required String password,
  }) async {
    final response = await dio.post('auth/login', data: {
      'national_id': civilId,
      'password': password,
      'device_name': 'mobile_device',
      'app_context': 'parent',
    });

    final data = response.data['data'];
    final user = data['user'];
    return AuthUser(
      id: user['id'].toString(),
      name: user['name'] ?? '',
      role: user['role'] ?? 'guardian',
      accessToken: data['token'] ?? response.data['token'],
    );
  }

  @override
  Future<void> requestPasswordReset({required String phoneOrUsername}) async {
    // Backend doesn't seem to have a dedicated password/forgot yet in AuthController
    // but we'll point it to the likely endpoint or keep it as placeholder
    await dio.post('auth/password/reset-request', data: {
      'national_id': phoneOrUsername,
    });
  }
}
