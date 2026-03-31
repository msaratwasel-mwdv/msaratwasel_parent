import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/profile/domain/entities/profile.dart';
import './profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio dio;

  ProfileRepositoryImpl({required this.dio});

  @override
  Future<Profile> fetchProfile() async {
    final response = await dio.get('profile');
    final data = response.data['data'];
    
    String? avatarUrl = data['avatar_url'] ?? data['image_url'];
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      avatarUrl = 'https://srv1428362.hstgr.cloud/storage/$avatarUrl';
    }

    return Profile(
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      languageCode: data['language'],
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await dio.put('profile', data: {
      'name': profile.name,
      'email': profile.email,
      'language': profile.languageCode,
    });
  }
}
