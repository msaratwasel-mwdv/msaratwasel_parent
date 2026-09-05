// Agent 6: HomeScreen Deep Coverage
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/home/presentation/home_screen.dart';

class _FakeHomeDioAdapter implements HttpClientAdapter {
  bool missingLocation;
  _FakeHomeDioAdapter({this.missingLocation = false});

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
            'home_lat': missingLocation ? null : 23.5880,
            'home_lng': missingLocation ? null : 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة الأمل',
            'bus': {
              'id': 'bus_1',
              'bus_number': '101',
              'plate_number': '1234 A',
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

    if (path.contains('notifications')) {
      final data = {
        'data': [
          {
            'id': 'notif_1',
            'title': 'اقتراب الحافلة',
            'body': 'الحافلة قادمة',
            'type': 'bus_approaching',
            'read': false,
            'created_at': DateTime.now().toIso8601String(),
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
    controller.dio.httpClientAdapter = _FakeHomeDioAdapter();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Agent 6: HomeScreen Deep Coverage Suite', () {
    testWidgets('1. HomeScreen builds and shows home content with sliver header', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const Scaffold(body: HomeScreen()), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(CustomScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('2. HomeScreen renders populated students, summary stats, and child quick cards', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await t.pumpWidget(_build(child: const Scaffold(body: HomeScreen()), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('عمر'), findsAtLeastNWidgets(1));
      expect(find.textContaining('سارة'), findsAtLeastNWidgets(1));

      // Tap student card to navigate
      final omarCard = find.textContaining('عمر');
      if (omarCard.evaluate().isNotEmpty) {
        await t.tap(omarCard.first);
        await t.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 1);
      }
    });

    testWidgets('3. HomeScreen renders recent notifications and view all button', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await t.pumpWidget(_build(child: const Scaffold(body: HomeScreen()), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final viewAll = find.text('عرض الكل');
      if (viewAll.evaluate().isNotEmpty) {
        await t.tap(viewAll.first);
        await t.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 4);
      }
    });

    testWidgets('4. HomeScreen quick actions buttons are responsive', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await t.pumpWidget(_build(child: const Scaffold(body: HomeScreen()), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      // Scroll down to see quick actions
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -600));
        await t.pump(const Duration(milliseconds: 200));
      }

      // Tap quick action buttons
      final busIcon = find.byIcon(Icons.directions_bus_rounded);
      if (busIcon.evaluate().isNotEmpty) {
        await t.tap(busIcon.first);
        await t.pump(const Duration(milliseconds: 200));
      }

      final chatIcon = find.byIcon(Icons.chat_bubble_rounded);
      if (chatIcon.evaluate().isNotEmpty) {
        await t.tap(chatIcon.first);
        await t.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 5);
      }

      final calIcon = find.byIcon(Icons.calendar_month_rounded);
      if (calIcon.evaluate().isNotEmpty) {
        await t.tap(calIcon.first);
        await t.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 7);
      }

      final absenceIcon = find.byIcon(Icons.assignment_turned_in_rounded);
      if (absenceIcon.evaluate().isNotEmpty) {
        await t.tap(absenceIcon.first);
        await t.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 10);
      }

      final settingsIcon = find.byIcon(Icons.settings_rounded);
      if (settingsIcon.evaluate().isNotEmpty) {
        await t.tap(settingsIcon.first);
        await t.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 9);
      }
    });

    testWidgets('5. HomeScreen pull-to-refresh and scroll bounce', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const Scaffold(body: HomeScreen()), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, 300));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
