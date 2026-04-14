import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_keys.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();
  Future<SharedPreferences> get prefs async => SharedPreferences.getInstance();

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> readAccessToken() async {
    return await _secureStorage.read(key: StorageKeys.accessToken);
  }

  Future<void> deleteAccessToken() async {
    await _secureStorage.delete(key: StorageKeys.accessToken);
  }

  Future<void> saveLocale(String code) async {
    final p = await prefs;
    await p.setString(StorageKeys.locale, code);
  }

  Future<String?> readLocale() async {
    final p = await prefs;
    return p.getString(StorageKeys.locale);
  }

  Future<void> saveFcmToken(String token) async {
    final p = await prefs;
    await p.setString(StorageKeys.fcmToken, token);
  }

  Future<String?> readFcmToken() async {
    final p = await prefs;
    return p.getString(StorageKeys.fcmToken);
  }

  Future<void> saveOnboardingSeen(bool seen) async {
    final p = await prefs;
    await p.setBool(StorageKeys.hasSeenOnboarding, seen);
  }

  Future<bool> readOnboardingSeen() async {
    final p = await prefs;
    return p.getBool(StorageKeys.hasSeenOnboarding) ?? false;
  }

  Future<void> saveUserData({
    required int id,
    required String name,
    String? nameEn,
    String? phone,
    String? email,
    String? nationalId,
    String? avatarUrl,
  }) async {
    final p = await prefs;
    await p.setInt(StorageKeys.userId, id);
    await p.setString(StorageKeys.userName, name);
    if (nameEn != null) await p.setString(StorageKeys.userNameEn, nameEn);
    if (phone != null) await p.setString(StorageKeys.userPhone, phone);
    if (email != null) await p.setString(StorageKeys.userEmail, email);
    if (nationalId != null) await p.setString(StorageKeys.userNationalId, nationalId);
    if (avatarUrl != null) await p.setString(StorageKeys.userAvatarUrl, avatarUrl);
  }

  Future<Map<String, dynamic>> readUserData() async {
    final p = await prefs;
    return {
      'id': p.getInt(StorageKeys.userId),
      'name': p.getString(StorageKeys.userName),
      'name_en': p.getString(StorageKeys.userNameEn),
      'phone': p.getString(StorageKeys.userPhone),
      'email': p.getString(StorageKeys.userEmail),
      'national_id': p.getString(StorageKeys.userNationalId),
      'avatar_url': p.getString(StorageKeys.userAvatarUrl),
    };
  }

  Future<void> clearAll() async {
    await deleteAccessToken();
    final p = await prefs;
    await p.remove(StorageKeys.userId);
    await p.remove(StorageKeys.userName);
    await p.remove(StorageKeys.userNameEn);
    await p.remove(StorageKeys.userPhone);
    await p.remove(StorageKeys.userEmail);
    await p.remove(StorageKeys.userNationalId);
    await p.remove(StorageKeys.userAvatarUrl);
  }
}
