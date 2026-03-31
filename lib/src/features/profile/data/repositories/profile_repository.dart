import '../../domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<void> updateProfile(Profile profile);

  Future<Profile> fetchProfile();
}
