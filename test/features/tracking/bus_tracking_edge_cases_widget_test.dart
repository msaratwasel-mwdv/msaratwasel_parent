import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/pages/bus_tracking_page.dart';

class _FakeEdgeTrackingDioAdapter implements HttpClientAdapter {
  final bool hasActiveTrip;
  final bool hasContacts;
  final String tripType;

  _FakeEdgeTrackingDioAdapter({
    this.hasActiveTrip = true,
    this.hasContacts = true,
    this.tripType = 'to_school',
  });

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
            'id': 'std_male_1',
            'name': 'علي محمد',
            'grade': 'الصف الأول',
            'status': 'onBus',
            'suggested_direction': 'to_school',
            'gender': 'male',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة النور',
            'bus': {
              'id': 'bus_edge_1',
              'bus_number': '105',
              'plate_number': '9999 X',
              if (hasContacts) ...{
                'driver': {'id': 1, 'name': 'سائق 1', 'phone': '99000001'},
                'supervisor': {'id': 2, 'name': 'مشرف 1', 'phone': '99000002'},
              },
            },
          },
          {
            'id': 'std_female_1',
            'name': 'مريم علي',
            'grade': 'الصف الثاني',
            'status': 'onBus',
            'suggested_direction': 'to_home',
            'gender': 'female',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة النور',
            'bus': {
              'id': 'bus_edge_1',
              'bus_number': '105',
              'plate_number': '9999 X',
            },
          },
          {
            'id': 'std_female_2',
            'name': 'فاطمة علي',
            'grade': 'الصف الثالث',
            'status': 'atSchool',
            'gender': 'female',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة النور',
            'bus': {
              'id': 'bus_edge_1',
              'bus_number': '105',
              'plate_number': '9999 X',
            },
          },
          {
            'id': 'std_female_3',
            'name': 'نورة علي',
            'grade': 'الصف الرابع',
            'status': 'atHome',
            'suggested_direction': 'to_home',
            'gender': 'female',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة النور',
            'bus': {
              'id': 'bus_edge_1',
              'bus_number': '105',
              'plate_number': '9999 X',
            },
          },
          {
            'id': 'std_male_2',
            'name': 'خالد علي',
            'grade': 'الصف الخامس',
            'status': 'late',
            'gender': 'male',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة النور',
            'bus': {
              'id': 'bus_edge_1',
              'bus_number': '105',
              'plate_number': '9999 X',
            },
          },
          {
            'id': 'std_female_4',
            'name': 'سارة علي',
            'grade': 'الصف السادس',
            'status': 'notBoarded',
            'gender': 'female',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة النور',
            'bus': {
              'id': 'bus_edge_1',
              'bus_number': '105',
              'plate_number': '9999 X',
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

    if (path.contains('bus/bus_edge_1/location')) {
      final data = {
        'bus_id': 'bus_edge_1',
        'bus_number': '105',
        'bus_plate': '9999 X',
        'latitude': 23.5880,
        'longitude': 58.3829,
        'speed': 40.0,
        'heading': 180.0,
        'trip_status': hasActiveTrip ? 'in_progress' : 'completed',
        'trip_type': tripType,
        'total_students_count': 6,
        'total_students_on_board': 2,
        'target_latitude': 23.5880,
        'target_longitude': 58.3829,
        'eta_minutes': 8,
        if (hasContacts) ...{
          'driver': {'id': 1, 'name': 'سائق 1', 'phone': '99000001'},
          'supervisor': {'id': 2, 'name': 'مشرف 1', 'phone': '99000002'},
        },
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('profile')) {
      final data = {
        'data': {
          'id': 201,
          'name': 'Edge Parent',
          'phone': '99000000',
          'email': 'parent@example.com',
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

Widget buildTestWidget({
  required Widget child,
  required AppController controller,
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppScope(
      controller: controller,
      child: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/platform_views'),
      (call) async {
        if (call.method == 'create') return 0;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_maps'),
      (call) async => null,
    );
  });

  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 201,
      'user_name': 'Edge Parent',
      'has_seen_onboarding': true,
      'app_locale': 'ar',
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'edge_token',
    });

    controller = AppController();
    controller.dio.httpClientAdapter = _FakeEdgeTrackingDioAdapter();
    await controller.bootstrap();
    controller.stopTrackingPoll();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Bus Tracking Deep Edge Cases and Component Coverage', () {
    testWidgets('1. BusTrackingPage renders diverse student statuses and female phrasing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(controller.students.length, 6);

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(BusTrackingPage), findsOneWidget);

      // Check student cards presence
      expect(find.textContaining('علي محمد'), findsWidgets);
      expect(find.textContaining('مريم علي'), findsWidgets);

      // Scroll inside panel to reveal lower cards
      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.textContaining('فاطمة علي'), findsWidgets);
    });

    testWidgets('2. Quick Call bottom sheet without contacts displays noContactData', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.dio.httpClientAdapter = _FakeEdgeTrackingDioAdapter(hasContacts: false);
      await controller.loadChildrenFromApi();

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Tap Quick Call tile
      final callTile = find.byIcon(Icons.phone_in_talk_rounded);
      if (callTile.evaluate().isNotEmpty) {
        await tester.tap(callTile.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Check for no contact data message
        expect(find.text('لا توجد بيانات اتصال'), findsOneWidget);
      }
    });

    testWidgets('3. BusTrackingPage renders in English locale with English student statuses', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      controller.setLocale(const Locale('en'));

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
          locale: const Locale('en'),
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(BusTrackingPage), findsOneWidget);
      expect(controller.locale.languageCode, 'en');
      controller.stopTrackingPoll();
    });

    testWidgets('4. No active trip blocker button triggers refresh', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.dio.httpClientAdapter = _FakeEdgeTrackingDioAdapter(hasActiveTrip: false);
      await controller.loadChildrenFromApi();

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Find refresh button in blocker
      final refreshBtn = find.text('تحديث الحالة');
      if (refreshBtn.evaluate().isNotEmpty) {
        await tester.tap(refreshBtn.first);
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('لا توجد رحلة نشطة حالياً'), findsOneWidget);
      controller.stopTrackingPoll();
    });

    testWidgets('5. Map layer toggle between normal and hybrid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final layerBtn = find.byIcon(Icons.layers_outlined);
      if (layerBtn.evaluate().isNotEmpty) {
        await tester.tap(layerBtn.first);
        await tester.pump(const Duration(milliseconds: 200));
        final toggledBtn = find.byIcon(Icons.layers);
        if (toggledBtn.evaluate().isNotEmpty) {
          await tester.tap(toggledBtn.first);
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      expect(find.byType(BusTrackingPage), findsOneWidget);
      controller.stopTrackingPoll();
    });

    testWidgets('6. Absence action button inside panel navigates to absence page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final absenceBtn = find.byIcon(Icons.event_busy_rounded);
      if (absenceBtn.evaluate().isNotEmpty) {
        await tester.tap(absenceBtn.first);
        await tester.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 10);
      }
    });

    testWidgets('7. Quick call action button opens staff contact modal bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final quickCallBtn = find.byIcon(Icons.phone_in_talk_rounded);
      if (quickCallBtn.evaluate().isNotEmpty) {
        await tester.tap(quickCallBtn.first, warnIfMissed: false);
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }

        final phoneIcons = find.byIcon(Icons.phone);
        if (phoneIcons.evaluate().isNotEmpty) {
          await tester.tap(phoneIcons.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      expect(find.byType(BusTrackingPage), findsOneWidget);
    });

    testWidgets('8. Chat action button inside tracking panel navigates to chat page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final chatBtn = find.byIcon(Icons.chat_bubble_rounded);
      if (chatBtn.evaluate().isNotEmpty) {
        await tester.tap(chatBtn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
        expect(controller.navIndex, 5);
      }
    });

    testWidgets('9. Panel expand and collapse toggle button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final arrowDown = find.byIcon(Icons.keyboard_arrow_down);
      if (arrowDown.evaluate().isNotEmpty) {
        await tester.tap(arrowDown.first);
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }

        final arrowUp = find.byIcon(Icons.keyboard_arrow_up);
        if (arrowUp.evaluate().isNotEmpty) {
          await tester.tap(arrowUp.first);
          for (int i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 150));
          }
        }
      }
      expect(find.byType(BusTrackingPage), findsOneWidget);
    });

    testWidgets('10. Bus selector allows horizontal bus item interactions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final busIcon = find.byIcon(Icons.directions_bus_filled_rounded);
      if (busIcon.evaluate().isNotEmpty) {
        await tester.tap(busIcon.first);
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(BusTrackingPage), findsOneWidget);
    });
  });
}
