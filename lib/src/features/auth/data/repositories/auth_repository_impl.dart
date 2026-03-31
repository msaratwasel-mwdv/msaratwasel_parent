import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/auth/domain/entities/auth_user.dart';
import './auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;

  AuthRepositoryImpl({required this.dio});

  @override
  Future<AuthUser> login({
    required String civilId,
    required String phoneNumber,
  }) async {
    final response = await dio.post('login', data: {
      'civil_id': civilId,
      'phone_number': phoneNumber,
      'type': 'guardian', // Based on the project context
    });

    final data = response.data['data'];
    return AuthUser(
      id: data['user']['id'].toString(),
      name: data['user']['name'] ?? '',
      role: data['user']['role'] ?? 'guardian',
      accessToken: data['access_token'],
    );
  }

  @override
  Future<void> requestPasswordReset({required String phoneOrUsername}) async {
    await dio.post('password/forgot', data: {
      'login': phoneOrUsername,
    });
  }
}
