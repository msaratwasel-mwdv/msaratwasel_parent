import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/profile/domain/entities/profile.dart';
import './profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio dio;

  ProfileRepositoryImpl({required this.dio});

  @override
  Future<Profile> fetchProfile() async {
    final response = await dio.get('parent/profile');
    final data = response.data['data'];
    
    String? avatarUrl = data['image_url'] ?? data['avatar_url'];
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      avatarUrl = 'http://10.60.17.139:8001/storage/$avatarUrl';
    }

    return Profile(
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      languageCode: 'ar', // Default or from local storage if not in API
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await dio.post('parent/profile/update', data: {
      'phone': profile.phone,
      'email': profile.email,
    });
  }
}
