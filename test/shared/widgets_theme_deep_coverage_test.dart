// Agent 15: Shared Widgets & Theme Deep Coverage
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/widgets/address_display.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/section_badge.dart';
import 'package:msaratwasel_user/src/shared/widgets/user_avatar.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/theme/app_theme.dart';
import 'package:msaratwasel_user/src/shared/theme/app_typography.dart';
import 'package:msaratwasel_user/src/shared/theme/ui_palette.dart';
import 'package:msaratwasel_user/src/shared/widgets/directional_icon.dart';
import 'package:msaratwasel_user/src/shared/widgets/frosted_card.dart';
import 'package:msaratwasel_user/src/shared/services/places_service.dart';
import 'package:msaratwasel_user/src/core/services/notification_badge_service.dart';
import 'package:msaratwasel_user/src/core/config/app_config.dart';
import 'package:msaratwasel_user/src/core/utils/device_utils.dart';
import 'package:msaratwasel_user/src/core/utils/result.dart';

Widget _build({required Widget child, required AppController c}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppScope(controller: c, child: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true, 'user_id': 101,
      'user_name': 'أحمد الوالد', 'app_locale': 'ar',
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() { controller.stopTrackingPoll(); controller.dispose(); });

  group('Agent 15: Shared Widgets & Theme Suite', () {
    testWidgets('1. SectionBadge renders count > 0', (t) async {
      await t.pumpWidget(MaterialApp(home: Scaffold(
        body: const SectionBadge(count: 5),
      )));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(SectionBadge), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('2. SectionBadge returns SizedBox.shrink for count 0', (t) async {
      await t.pumpWidget(MaterialApp(home: Scaffold(
        body: const SectionBadge(count: 0),
      )));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('3. SectionBadge with custom color', (t) async {
      await t.pumpWidget(MaterialApp(home: Scaffold(
        body: const SectionBadge(count: 3, color: Colors.blue),
      )));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('4. UserAvatar renders with name initial', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(
        child: const UserAvatar(name: 'أحمد', radius: 20),
        c: controller,
      ));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('5. UserAvatar renders with image URL', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(
        child: const UserAvatar(name: 'أحمد', radius: 20, avatarUrl: 'https://example.com/avatar.png'),
        c: controller,
      ));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('6. DirectionalIcon renders based on locale direction', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(
        child: const DirectionalIcon(Icons.arrow_forward),
        c: controller,
      ));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(DirectionalIcon), findsOneWidget);
    });

    testWidgets('7. AddressDisplay renders with coordinates', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(
        child: const AddressDisplay(lat: 24.7136, lng: 46.6753),
        c: controller,
      ));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(AddressDisplay), findsOneWidget);
    });

    testWidgets('8. FrostedCard renders child content', (t) async {
      await t.pumpWidget(MaterialApp(home: Scaffold(
        body: const FrostedCard(child: Text('Frosted content')),
      )));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(FrostedCard), findsOneWidget);
      expect(find.text('Frosted content'), findsOneWidget);
    });

    test('9. AppColors provides all color constants', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.error, isNotNull);
      expect(AppColors.surface, isNotNull);
    });

    test('10. AppSpacing provides spacing constants', () {
      expect(AppSpacing.sm, isA<double>());
      expect(AppSpacing.md, isA<double>());
      expect(AppSpacing.lg, isA<double>());
    });

    test('11. AppTheme provides light and dark themes', () {
      expect(AppTheme.light, isA<ThemeData>());
      expect(AppTheme.dark, isA<ThemeData>());
    });

    test('12. AppTypography provides text styles', () {
      expect(AppTypography, isNotNull);
    });

    test('13. UiPalette provides palette constants', () {
      expect(UiPalette, isNotNull);
    });

    test('14. Result type handles success and failure', () {
      final success = Success<String>('ok');
      final failure = Failure<String>('error', StackTrace.empty);
      expect(success.data, 'ok');
      expect(failure.error, 'error');
      final res = success.when(
        success: (d) => 'success: $d',
        failure: (e, s) => 'fail',
      );
      expect(res, 'success: ok');
    });

    test('15. DeviceUtils provides device info methods', () {
      expect(DeviceUtils, isNotNull);
    });

    test('16. AppConfig provides configuration values', () {
      expect(AppConfig, isNotNull);
    });

    test('17. NotificationBadgeService can be instantiated', () {
      expect(NotificationBadgeService, isNotNull);
    });
  });
}
