import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/core/storage/storage_service.dart';
import 'package:msaratwasel_user/src/core/services/notification_badge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    storageService = StorageService();
  });

  group('StorageService Core Unit Tests', () {
    test('1. Access token write, read, and delete round-trip', () async {
      expect(await storageService.readAccessToken(), isNull);

      await storageService.saveAccessToken('secret_jwt_token_123');
      expect(await storageService.readAccessToken(), 'secret_jwt_token_123');

      await storageService.deleteAccessToken();
      expect(await storageService.readAccessToken(), isNull);
    });

    test('2. Locale persistence round-trip', () async {
      expect(await storageService.readLocale(), isNull);

      await storageService.saveLocale('ar');
      expect(await storageService.readLocale(), 'ar');

      await storageService.saveLocale('en');
      expect(await storageService.readLocale(), 'en');
    });

    test('3. FCM token persistence round-trip', () async {
      expect(await storageService.readFcmToken(), isNull);

      await storageService.saveFcmToken('fcm_device_token_xyz');
      expect(await storageService.readFcmToken(), 'fcm_device_token_xyz');
    });

    test('4. Onboarding flag default and persistence', () async {
      expect(await storageService.readOnboardingSeen(), isFalse);

      await storageService.saveOnboardingSeen(true);
      expect(await storageService.readOnboardingSeen(), isTrue);
    });

    test('5. User data saving and reading map structure', () async {
      await storageService.saveUserData(
        id: 77,
        name: 'Saad Al-Ghamdi',
        nameEn: 'Saad Al-Ghamdi',
        phone: '0550000000',
        email: 'saad@example.com',
        nationalId: '1020304050',
        avatarUrl: 'https://example.com/avatar.png',
      );

      final userData = await storageService.readUserData();

      expect(userData['id'], 77);
      expect(userData['name'], 'Saad Al-Ghamdi');
      expect(userData['email'], 'saad@example.com');
      expect(userData['national_id'], '1020304050');
      expect(userData['avatar_url'], 'https://example.com/avatar.png');
    });
  });

  group('NotificationBadgeService Suite', () {
    test('6. NotificationBadgeService sync handles 0 and positive counts safely', () async {
      // Must not throw or crash even if native platform badge channel is absent in unit tests
      await NotificationBadgeService.sync(0);
      await NotificationBadgeService.sync(5);
    });
  });
}
