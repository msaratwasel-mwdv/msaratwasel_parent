// Shared test helper for all parent app widget tests.
// All 15 subagents use this file for common setup logic.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';

/// Seeds SharedPreferences and SecureStorage with test defaults.
Future<AppController> createTestController({
  Map<String, Object>? prefs,
  Map<String, String>? secure,
}) async {
  SharedPreferences.setMockInitialValues({
    'has_seen_onboarding': true,
    'user_id': 101,
    'user_name': 'أحمد الوالد',
    'user_email': 'parent@test.com',
    'user_phone': '0555555555',
    'app_locale': 'ar',
    'theme_mode': 'light',
    'my_student_ids': ['st_10', 'st_11'],
    ...?prefs,
  });
  FlutterSecureStorage.setMockInitialValues({
    'access_token': 'valid_test_token',
    ...?secure,
  });
  final controller = AppController();
  await controller.bootstrap();
  return controller;
}

/// Wraps [child] in MaterialApp + AppScope for widget testing.
Widget buildTestableWidget({
  required Widget child,
  required AppController controller,
  bool useScaffold = true,
}) {
  final content = useScaffold ? Scaffold(body: child) : child;
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    home: AppScope(
      controller: controller,
      child: content,
    ),
  );
}
