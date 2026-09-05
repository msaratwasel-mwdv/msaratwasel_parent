import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/absence/presentation/pages/absence_history_page.dart';

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

  Widget buildTestableWidget({
    required AppController controller,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: AbsenceHistoryPage(),
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

  group('AbsenceHistoryPage Widget Suite', () {
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

    testWidgets('1. Displays empty state when no absence requests exist', (tester) async {
      adapter.responses['parent/absence-requests'] = {
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

      await tester.pumpWidget(buildTestableWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('سجل الغياب'), findsOneWidget); // Header
      expect(find.text('لا يوجد سجل غياب'), findsOneWidget);
    });

    testWidgets('2. Displays requests with status badges, types, notes, rejection reasons, and dark mode', (tester) async {
      adapter.responses['parent/absence-requests'] = {
        'success': true,
        'data': [
          {
            'id': 1,
            'student_id': 101,
            'student_name': 'أحمد سعيد',
            'student_name_en': 'Ahmed Saeed',
            'date': '2026-09-10',
            'type': 'morning',
            'status': 'approved',
            'reason': 'عذر طبي لدى المستشفى',
          },
          {
            'id': 2,
            'student_id': 102,
            'student_name': 'سارة سعيد',
            'student_name_en': 'Sara Saeed',
            'date': '2026-09-11',
            'type': 'return_only',
            'status': 'rejected',
            'reason': 'استئذان عائلي',
            'rejection_reason': 'يرجى تقديم الطلب قبل 24 ساعة',
          },
          {
            'id': 3,
            'student_id': 103,
            'student_name': '', // Tests empty student name fallback ('الطالب')
            'student_name_en': '',
            'date': '2026-09-12',
            'type': 'both',
            'status': 'pending',
            'note': null,
          }
        ],
      };

      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      // Test dark mode
      await tester.pumpWidget(buildTestableWidget(
        controller: controller,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      // Student names
      expect(find.text('أحمد سعيد'), findsOneWidget);
      expect(find.text('سارة سعيد'), findsOneWidget);
      expect(find.text('طالب'), findsOneWidget);

      // Status badges
      expect(find.text('مقبول'), findsOneWidget);
      expect(find.text('مرفوض'), findsOneWidget);
      expect(find.text('قيد المراجعة'), findsOneWidget);

      // Types
      expect(find.text('ذهاب فقط (صباحاً)'), findsOneWidget);
      expect(find.text('يوم كامل'), findsNWidgets(2)); // Both Sara and 3rd student

      // Notes & Rejection reason
      expect(find.text('عذر طبي لدى المستشفى'), findsOneWidget);
      expect(find.text('سبب الرفض:'), findsOneWidget);
      expect(find.text('يرجى تقديم الطلب قبل 24 ساعة'), findsOneWidget);

      // Pull to refresh interaction
      await tester.fling(find.text('أحمد سعيد'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('3. Handles notification tap deep linking check in didChangeDependencies', (tester) async {
      adapter.responses['parent/absence-requests'] = {
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

      // Set pending notification ID
      controller.setPendingNotificationId('notif_absence_999');
      expect(controller.pendingNotificationId, 'notif_absence_999');

      await tester.pumpWidget(buildTestableWidget(controller: controller));
      await tester.pumpAndSettle();

      // Check that pendingNotificationId was cleared upon page arrival
      expect(controller.pendingNotificationId, isNull);
    });
  });
}
