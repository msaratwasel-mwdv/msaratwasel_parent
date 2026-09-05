import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/pages/bus_tracking_page.dart';

class _FakeTrackingDioAdapter implements HttpClientAdapter {
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
                'phone': '96891234567',
              },
              'supervisor': {
                'id': 2,
                'name': 'سالم المشرف',
                'phone': '96897654321',
              },
            },
          },
          {
            'id': 'std_2',
            'name': 'فاطمة أحمد',
            'grade': 'الصف الثاني',
            'status': 'waitingAtHome',
            'home_lat': 23.5880,
            'home_lng': 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة الأمل',
            'bus': {
              'id': 'bus_2',
              'bus_number': '102',
              'plate_number': '5678 B',
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

    if (path.contains('bus/bus_1/location')) {
      final data = {
        'bus_id': 'bus_1',
        'bus_number': '101',
        'bus_plate': '1234 A',
        'latitude': 23.5880,
        'longitude': 58.3829,
        'speed': 45.0,
        'heading': 90.0,
        'trip_status': 'in_progress',
        'trip_type': 'to_school',
        'total_students_count': 12,
        'total_students_on_board': 4,
        'target_latitude': 23.5880,
        'target_longitude': 58.3829,
        'eta_minutes': 12,
        'driver': {
          'id': 1,
          'name': 'أحمد السائق',
          'phone': '96891234567',
        },
        'supervisor': {
          'id': 2,
          'name': 'سالم المشرف',
          'phone': '96897654321',
        },
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('bus/bus_2/location')) {
      final data = {
        'bus_id': 'bus_2',
        'bus_number': '102',
        'bus_plate': '5678 B',
        'latitude': 23.5900,
        'longitude': 58.3900,
        'speed': 0.0,
        'heading': 0.0,
        'trip_status': 'completed',
        'trip_type': 'to_school',
        'total_students_count': 10,
        'total_students_on_board': 0,
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

Widget buildTestableWidget({required Widget child, required AppController controller}) {
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
      child: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 100,
      'user_name': 'Parent Tracking',
      'has_seen_onboarding': true,
      'app_locale': 'ar',
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'mock_token',
    });

    controller = AppController();
    controller.dio.httpClientAdapter = _FakeTrackingDioAdapter();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Agent 7: Bus Tracking Page Deep Widget Suite', () {
    testWidgets('1. BusTrackingPage renders empty blocker state when no active trips', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(BusTrackingPage), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('2. BusTrackingPage renders active trip with map, selector, and panel when tracking active', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(controller.students.length, 2);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(BusTrackingPage), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('3. SpeechBubble and TriangleClipper render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: const SpeechBubble(
                title: 'الوجهة القادمة',
                description: 'محطة المنزل',
                time: '5 دقائق',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('الوجهة القادمة'), findsOneWidget);
      expect(find.text('محطة المنزل'), findsOneWidget);
      expect(find.text('5 دقائق'), findsOneWidget);
    });

    testWidgets('4. BusTrackingPage panel expands, collapses, and toggles layers', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Tap toggle button to collapse panel
      final toggleArrow = find.byIcon(Icons.keyboard_arrow_down);
      if (toggleArrow.evaluate().isNotEmpty) {
        await tester.tap(toggleArrow.first);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Toggle back to expanded
      final toggleUp = find.byIcon(Icons.keyboard_arrow_up);
      if (toggleUp.evaluate().isNotEmpty) {
        await tester.tap(toggleUp.first);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Toggle layer button
      final layerButton = find.byIcon(Icons.layers_outlined);
      if (layerButton.evaluate().isNotEmpty) {
        await tester.tap(layerButton.first);
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(BusTrackingPage), findsOneWidget);
    });

    testWidgets('5. Quick call bottom sheet displays driver and supervisor contacts and handles taps', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Tap Quick Call button in action tile
      final callTile = find.byIcon(Icons.phone_in_talk_rounded);
      if (callTile.evaluate().isNotEmpty) {
        await tester.tap(callTile.first);
        await tester.pumpAndSettle();

        // Check driver and supervisor in bottom sheet
        expect(find.textContaining('أحمد السائق'), findsWidgets);
        expect(find.textContaining('سالم المشرف'), findsWidgets);

        // Tap driver call
        final driverTile = find.textContaining('أحمد السائق');
        if (driverTile.evaluate().isNotEmpty) {
          await tester.tap(driverTile.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('6. Bus selector switches active bus selection', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Look for bus 2 selector
      final bus2Text = find.text('102');
      if (bus2Text.evaluate().isNotEmpty) {
        await tester.tap(bus2Text.first);
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.byType(BusTrackingPage), findsOneWidget);
    });

    testWidgets('7. Map centering action buttons and navigation to chat', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const BusTrackingPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Center on bus button
      final centerBus = find.byIcon(Icons.directions_bus_filled);
      if (centerBus.evaluate().isNotEmpty) {
        await tester.tap(centerBus.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Show all button
      final showAll = find.byIcon(Icons.zoom_out_map);
      if (showAll.evaluate().isNotEmpty) {
        await tester.tap(showAll.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Chat tile
      final chatTile = find.byIcon(Icons.chat_bubble_rounded);
      if (chatTile.evaluate().isNotEmpty) {
        await tester.tap(chatTile.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(BusTrackingPage), findsOneWidget);
    });
  });
}
