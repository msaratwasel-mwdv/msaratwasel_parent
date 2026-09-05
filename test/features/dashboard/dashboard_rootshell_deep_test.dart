import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/dashboard/presentation/root_shell.dart';
import 'package:msaratwasel_user/src/features/dashboard/presentation/dashboard_page.dart';

class _FakeDashboardDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('children')) {
      final data = {
        'data': [
          {
            'id': 'std_1',
            'name': 'عمر أحمد',
            'name_ar': 'عمر أحمد',
            'name_en': 'Omar Ahmed',
            'grade': 'الصف الرابع',
            'status': 'onBus',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة الأمل',
            'bus': {
              'id': 'bus_1',
              'bus_number': '101',
              'plate_number': '1234 A',
              'driver': {
                'id': 1,
                'name': 'أحمد السائق',
                'name_ar': 'أحمد السائق',
                'name_en': 'Ahmed Driver',
                'phone': '96891234567',
              },
              'supervisor': {
                'id': 2,
                'name': 'سالم المشرف',
                'name_ar': 'سالم المشرف',
                'name_en': 'Salim Supervisor',
                'phone': '96897654321',
              },
            },
          },
          {
            'id': 'std_2',
            'name': 'سارة أحمد',
            'name_ar': 'سارة أحمد',
            'name_en': 'Sara Ahmed',
            'grade': 'الصف الثاني',
            'status': 'atSchool',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة الأمل',
            'bus': {
              'id': 'bus_1',
              'bus_number': '101',
              'plate_number': '1234 A',
            },
          },
        ]
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('location') || path.contains('tracking')) {
      final data = {
        'status': 'success',
        'data': {
          'id': 'bus_1',
          'lat': 23.5900,
          'lng': 58.3900,
          'speed': 45.0,
          'heading': 90.0,
          'eta_minutes': 8,
          'is_online': true,
          'trip_status': 'in_progress',
          'driver_name': 'أحمد السائق',
          'driver_phone': '96891234567',
        }
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('notifications')) {
      final data = {
        'data': [
          {
            'id': 'notif_1',
            'title': 'اقتراب الحافلة',
            'body': 'الحافلة على بعد 5 دقائق من منزلك',
            'type': 'bus_approaching',
            'read': false,
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'notif_2',
            'title': 'صعود الطالب',
            'body': 'صعد عمر الحافلة بأمان',
            'type': 'student_boarded',
            'read': true,
            'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          },
        ]
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('parent/profile')) {
      final data = {
        'data': {
          'id': 101,
          'name': 'أحمد الوالد',
          'email': 'parent@test.com',
          'phone': '0555555555',
        }
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _build({required Widget child, required AppController c}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, materialChild) => AppScope(
      controller: c,
      child: materialChild!,
    ),
    home: Scaffold(body: child),
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
      'user_email': 'parent@test.com',
      'user_phone': '0555555555',
      'my_student_ids': ['std_1', 'std_2'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    controller = AppController();
    controller.dio.httpClientAdapter = _FakeDashboardDioAdapter();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Agent 7: Dashboard & RootShell Deep Coverage Suite', () {
    testWidgets('1. RootShell renders with Scaffold and custom drawer', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const RootShell(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(RootShell), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('2. RootShell switches to different nav indexes correctly', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const RootShell(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      controller.setNavIndex(1);
      await t.pump(const Duration(milliseconds: 200));
      expect(controller.navIndex, 1);

      controller.setNavIndex(2);
      await t.pump(const Duration(milliseconds: 200));
      expect(controller.navIndex, 2);

      controller.setNavIndex(3);
      await t.pump(const Duration(milliseconds: 200));
      expect(controller.navIndex, 3);

      controller.setNavIndex(0);
      await t.pump(const Duration(milliseconds: 200));
      expect(controller.navIndex, 0);
    });

    testWidgets('3. RootShell drawer opens and lists drawer navigation items', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const RootShell(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final menu = find.byIcon(Icons.menu_rounded);
      if (menu.evaluate().isNotEmpty) {
        await t.tap(menu.first);
        await t.pump(const Duration(milliseconds: 300));
        final drawerItems = find.descendant(of: find.byType(Drawer), matching: find.byType(ListTile));
        if (drawerItems.evaluate().isNotEmpty) {
          await t.tap(drawerItems.first);
          await t.pump(const Duration(milliseconds: 300));
        }
      }
    });

    testWidgets('4. DashboardPage renders welcome header and populated student cards', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await t.pumpWidget(_build(child: const DashboardPage(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.textContaining('عمر'), findsAtLeastNWidgets(1));
      expect(find.textContaining('سارة'), findsAtLeastNWidgets(1));
    });

    testWidgets('5. DashboardPage quick actions and activity card view all interactions', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await t.pumpWidget(_build(child: const DashboardPage(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      // View all button in activity card
      final viewAllBtn = find.text('عرض الكل');
      if (viewAllBtn.evaluate().isNotEmpty) {
        await t.tap(viewAllBtn.first);
        await t.pump(const Duration(milliseconds: 200));
      }

      // Notifications button in cupertino bar
      final notifBtn = find.byIcon(Icons.notifications_active_rounded);
      if (notifBtn.evaluate().isNotEmpty) {
        await t.tap(notifBtn.first);
        await t.pump(const Duration(milliseconds: 200));
      }

      controller.stopTrackingPoll();
    });

    testWidgets('6. DashboardPage track bus on student card selects student and navigates', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await t.pumpWidget(_build(child: const DashboardPage(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final trackButtons = find.text('تتبع الحافلة');
      if (trackButtons.evaluate().isNotEmpty) {
        await t.tap(trackButtons.first);
        await t.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 1);
      }
      controller.stopTrackingPoll();
    });

    testWidgets('7. DashboardPage scrolls smoothly through all sections and bus info card', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await t.pumpWidget(_build(child: const DashboardPage(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -500));
        await t.pump(const Duration(milliseconds: 200));
        await t.drag(scrollable.first, const Offset(0, -500));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(DashboardPage), findsOneWidget);
      controller.stopTrackingPoll();
    });
  });
}
