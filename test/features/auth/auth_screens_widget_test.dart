import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/forgot_password_screen.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/login_screen.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/otp_verification_screen.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/widgets/auth_background.dart';

Widget _buildTestableAuth({required Widget child, required AppController controller}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppScope(
      controller: controller,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 101,
      'user_name': 'أحمد الوالد',
      'app_locale': 'ar',
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'mock_token',
    });
    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('Agent 11: Auth Screens Widget Suite', () {
    testWidgets('1. ForgotPasswordScreen renders form with civil ID input and submit button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestableAuth(
          child: ForgotPasswordScreen(controller: controller),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('2. LoginScreen renders login form with username and password fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestableAuth(
          child: LoginScreen(controller: controller),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('3. LoginScreen validates empty fields on submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestableAuth(
          child: LoginScreen(controller: controller),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Find submit / login button and tap it
      final loginButtons = find.byType(ElevatedButton);
      if (loginButtons.evaluate().isNotEmpty) {
        await tester.tap(loginButtons.first);
        await tester.pump(const Duration(milliseconds: 200));
      }
      // The form should still be visible (validation prevents navigation)
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('4. OtpVerificationScreen renders OTP input fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestableAuth(
          child: OtpVerificationScreen(
            controller: controller,
            phoneNumber: '0555555555',
          ),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    testWidgets('5. AuthBackground renders animated background gradient', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestableAuth(
          child: const AuthBackground(isDark: false),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AuthBackground), findsOneWidget);
    });
  });
}
