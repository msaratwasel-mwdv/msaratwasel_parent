import '../../domain/entities/profile.dart';

abstract class ProfileRepository {
  /// TODO: call UPDATE_PROFILE_API.
  Future<void> updateProfile(Profile profile);

  /// TODO: fetch current profile details.
  Future<Profile> fetchProfile();
}
