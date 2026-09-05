import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication & Session Baseline Suite', () {
    test('1. Unauthenticated bootstrap cleans stale tokens and sets isAuthenticated = false', () async {
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
        // No access token in storage
      });
      FlutterSecureStorage.setMockInitialValues({});

      final controller = AppController();
      await controller.bootstrap();

      expect(controller.isBootCompleted, isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.userName, isEmpty);

      controller.dispose();
    });

    test('2. Authenticated bootstrap loads user profile and initializes session', () async {
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
        'user_id': 77,
        'user_name': 'خالد المنذري',
        'user_name_en': 'Khalid Al-Manthari',
        'app_locale': 'ar',
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'mock_valid_token',
      });

      final controller = AppController();
      await controller.bootstrap();

      expect(controller.isBootCompleted, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.userName, 'خالد المنذري');
      expect(controller.userNameEn, 'Khalid Al-Manthari');
      expect(controller.userId, 77);

      controller.dispose();
    });

    test('3. Logout clears in-memory state and persisted user session', () async {
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
        'user_id': 77,
        'user_name': 'خالد المنذري',
        'processed_cids': ['cid_1', 'cid_2'],
        'my_student_ids': ['st_10'],
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'mock_valid_token',
      });

      final controller = AppController();
      await controller.bootstrap();
      expect(controller.isAuthenticated, isTrue);

      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.userId, isNull);
      expect(controller.userName, isEmpty);
      expect(controller.notifications, isEmpty);
      expect(controller.students, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('user_id'), isNull);
      expect(prefs.getStringList('processed_cids'), isNull);
      expect(prefs.getStringList('my_student_ids'), isNull);

      controller.dispose();
    });

    test('4. Language toggle updates locale and persists preference', () async {
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
        'app_locale': 'ar',
      });
      FlutterSecureStorage.setMockInitialValues({});

      final controller = AppController();
      await controller.bootstrap();

      expect(controller.locale.languageCode, 'ar');

      controller.updateLocale(const Locale('en'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.locale.languageCode, 'en');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'en');

      controller.dispose();
    });

    test('5. Theme toggle switches themeMode and notifies listeners', () async {
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
      });
      FlutterSecureStorage.setMockInitialValues({});

      final controller = AppController();
      await controller.bootstrap();

      bool notified = false;
      controller.addListener(() => notified = true);

      controller.toggleTheme(false); // currently light -> toggle to dark
      expect(controller.themeMode, ThemeMode.dark);
      expect(notified, isTrue);

      controller.toggleTheme(true); // currently dark -> toggle to light
      expect(controller.themeMode, ThemeMode.light);

      controller.dispose();
    });
  });
}
