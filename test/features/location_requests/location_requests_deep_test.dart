import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/location_requests/presentation/pages/location_requests_page.dart';

class _FakeLocationDioAdapter implements HttpClientAdapter {
  bool returnPopulated = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('location-requests')) {
      if (returnPopulated) {
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {
                'id': '1',
                'student_id': 'std_1',
                'student_name': 'عمر أحمد',
                'new_latitude': 23.5880,
                'new_longitude': 58.3829,
                'status': 'approved',
                'created_at': '2026-09-01T10:30:00Z',
              },
              {
                'id': '2',
                'student_id': 'std_99',
                'student_name': 'سارة خالد',
                'new_latitude': 23.6100,
                'new_longitude': 58.4100,
                'status': 'rejected',
                'rejection_reason': 'العنوان خارج نطاق التغطية للحافلة',
                'created_at': '2026-09-02T14:15:00Z',
              },
              {
                'id': '3',
                'student_id': 'std_1',
                'student_name': 'عمر أحمد',
                'new_latitude': 23.5950,
                'new_longitude': 58.3950,
                'status': 'pending',
                'created_at': '2026-09-03T09:00:00Z',
              },
              {
                'id': '4',
                'student_id': 'std_1',
                'student_name': 'عمر أحمد',
                'status': 'custom_status',
                'created_at': '2026-09-04T08:00:00Z',
              },
            ]
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      } else {
        return ResponseBody.fromString(
          jsonEncode({'data': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
    }

    return ResponseBody.fromString(
      jsonEncode({'data': []}),
      400,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _wrapWithAppScope({required Widget child, required AppController controller}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, materialChild) => AppScope(
      controller: controller,
      child: materialChild!,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;
  late _FakeLocationDioAdapter adapter;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 101,
      'user_name': 'أحمد الوالد',
      'app_locale': 'ar',
      'my_student_ids': ['std_1'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    adapter = _FakeLocationDioAdapter();
    controller = AppController();
    controller.dio.httpClientAdapter = adapter;
    await controller.bootstrap();
    controller.stopTrackingPoll();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('LocationRequestsPage Deep Coverage Suite', () {
    testWidgets('1. LocationRequestsPage renders empty state when requests list is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.returnPopulated = false;
      await tester.runAsync(() async {
        await controller.loadLocationRequestsFromApi();
      });
      controller.stopTrackingPoll();

      await tester.pumpWidget(_wrapWithAppScope(child: const LocationRequestsPage(), controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LocationRequestsPage), findsOneWidget);
      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
    });

    testWidgets('2. LocationRequestsPage renders populated cards with approved, rejected, and pending states', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.returnPopulated = true;
      await tester.runAsync(() async {
        await controller.loadLocationRequestsFromApi();
      });
      controller.stopTrackingPoll();

      await tester.pumpWidget(_wrapWithAppScope(child: const LocationRequestsPage(), controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LocationRequestsPage), findsOneWidget);
      expect(find.text('عمر أحمد'), findsAtLeastNWidgets(1));
      expect(find.text('سارة خالد'), findsOneWidget);
      expect(find.text('العنوان خارج نطاق التغطية للحافلة'), findsOneWidget);
      expect(find.text('0.000000, 0.000000'), findsOneWidget);
    });

    testWidgets('3. LocationRequestsPage consumes pendingNotificationId on mount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.setPendingNotificationId('loc_req_pending');

      await tester.pumpWidget(_wrapWithAppScope(child: const LocationRequestsPage(), controller: controller));
      await tester.pump(const Duration(milliseconds: 100));
      controller.stopTrackingPoll();

      expect(controller.pendingNotificationId, isNull);
    });

    testWidgets('4. LocationRequestsPage handles scroll and dark theme', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.returnPopulated = true;
      await tester.runAsync(() async {
        await controller.loadLocationRequestsFromApi();
      });
      controller.stopTrackingPoll();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, materialChild) => AppScope(
            controller: controller,
            child: materialChild!,
          ),
          home: const Scaffold(body: LocationRequestsPage()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      controller.stopTrackingPoll();

      final scrollable = find.byType(CustomScrollView);
      expect(scrollable, findsOneWidget);
      await tester.drag(scrollable, const Offset(0, -150));
      await tester.pump(const Duration(milliseconds: 100));
      controller.stopTrackingPoll();
    });
  });
}
