import 'package:shared_preferences/shared_preferences.dart';

import 'storage_keys.dart';

class StorageService {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveAccessToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.accessToken, token);
  }

  Future<String?> readAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.accessToken);
  }

  Future<void> saveLocale(String code) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.locale, code);
  }

  Future<String?> readLocale() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.locale);
  }

  Future<void> saveFcmToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.fcmToken, token);
  }

  Future<String?> readFcmToken() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.fcmToken);
  }
}
