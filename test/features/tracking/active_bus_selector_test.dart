import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/widgets/active_bus_selector.dart';

class _MockApiAdapter implements HttpClientAdapter {
  Map<String, dynamic> responses = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    for (final entry in responses.entries) {
      if (options.path.contains(entry.key)) {
        return ResponseBody.fromString(
          jsonEncode(entry.value),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
    }

    if (options.path.contains('profile')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {'id': 101, 'name': 'Parent Test', 'phone': '96812345678'},
          'success': true,
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': [], 'success': true}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(AppController controller) {
    return AppScope(
      controller: controller,
      child: const MaterialApp(
        home: Scaffold(
          body: ActiveBusSelector(),
        ),
      ),
    );
  }

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );
  });

  group('ActiveBusSelector Widget Suite', () {
    late AppController controller;
    late _MockApiAdapter adapter;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
        'user_name': 'Parent Test',
        'has_seen_onboarding': true,
        'app_locale': 'ar',
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'mock_jwt_token',
      });

      adapter = _MockApiAdapter();
    });

    tearDown(() {
      controller.stopTrackingPoll();
      controller.dispose();
    });

    testWidgets('1. Returns SizedBox.shrink when no trip groups exist', (tester) async {
      adapter.responses['parent/children'] = {
        'success': true,
        'data': [],
      };

      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      await tester.pumpWidget(buildTestableWidget(controller));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('2. Returns SizedBox.shrink when only one bus group exists', (tester) async {
      adapter.responses['parent/children'] = {
        'success': true,
        'data': [
          {
            'id': 'st_1',
            'name': 'أحمد',
            'name_en': 'Ahmed',
            'grade': '3',
            'school_id': 'sch_1',
            'status': 'onBus',
            'bus': {
              'id': 'bus_101',
              'bus_number': '101',
              'bus_plate': '1234 A',
              'latitude': 23.58,
              'longitude': 58.40,
            }
          }
        ]
      };

      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      await tester.pumpWidget(buildTestableWidget(controller));
      await tester.pumpAndSettle();

      expect(controller.allTripGroups.length, 1);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('3. Renders list when multiple bus groups exist and handles bus selection', (tester) async {
      adapter.responses['parent/children'] = {
        'success': true,
        'data': [
          {
            'id': 'st_1',
            'name': 'أحمد',
            'name_en': 'Ahmed',
            'grade': '3',
            'school_id': 'sch_1',
            'status': 'onBus',
            'bus': {
              'id': 'bus_101',
              'bus_number': '101',
              'bus_plate': '1234 A',
              'latitude': 23.58,
              'longitude': 58.40,
            }
          },
          {
            'id': 'st_2',
            'name': 'فاطمة',
            'name_en': 'Fatima',
            'grade': '5',
            'school_id': 'sch_1',
            'status': 'onBus',
            'bus': {
              'id': 'bus_101',
              'bus_number': '101',
              'bus_plate': '1234 A',
              'latitude': 23.58,
              'longitude': 58.40,
            }
          },
          {
            'id': 'st_3',
            'name': 'عمر',
            'name_en': 'Omar',
            'grade': '1',
            'school_id': 'sch_1',
            'status': 'waiting',
            'bus': {
              'id': 'bus_202',
              'bus_number': '202',
              'bus_plate': '5678 B',
              'latitude': 23.60,
              'longitude': 58.42,
            }
          }
        ]
      };

      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      await tester.pumpWidget(buildTestableWidget(controller));
      await tester.pumpAndSettle();

      expect(controller.allTripGroups.length, 2);
      expect(find.byType(ListView), findsOneWidget);

      // Bus titles
      expect(find.text('حافلة 101'), findsOneWidget);
      expect(find.text('حافلة 202'), findsOneWidget);

      // Multiple students badge on bus 101 (students count = 2)
      expect(find.text('2'), findsOneWidget);

      // Tapping on bus 202 selects it
      await tester.tap(find.text('حافلة 202'));
      await tester.pumpAndSettle();

      expect(controller.selectedBusId, 'bus_202');

      // Tapping on bus 101 re-selects it
      await tester.tap(find.text('حافلة 101'));
      await tester.pumpAndSettle();

      expect(controller.selectedBusId, 'bus_101');
    });
  });
}
