import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/students/presentation/pages/child_list_page.dart';

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
    Widget? child,
    void Function(Student)? onChildDetailsPushed,
  }) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        onGenerateRoute: (settings) {
          if (settings.name == '/child-details') {
            onChildDetailsPushed?.call(settings.arguments as Student);
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Child Details Screen')),
            );
          }
          return null;
        },
        home: child ?? const ChildListPage(),
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

  group('ChildListPage Widget Suite', () {
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

    testWidgets('1. Shows empty state when no students exist', (tester) async {
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

      await tester.pumpWidget(buildTestableWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('أبنائي'), findsOneWidget); // title
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('2. Displays students list with avatar letter fallback, grade, school and handles tap', (tester) async {
      adapter.responses['parent/children'] = {
        'success': true,
        'data': [
          {
            'id': 'std_1',
            'name': 'أحمد سعيد',
            'name_en': 'Ahmed Saeed',
            'grade': 'الصف الثالث',
            'grade_en': 'Grade 3',
            'school_id': 'sch_1',
            'school': {'name': 'مدرسة النور'},
            'status': 'onBus',
            'bus': {
              'id': 'bus_101',
              'bus_number': '101',
              'bus_plate': '1234 A',
            }
          },
          {
            'id': 'std_2',
            'name': 'فاطمة سعيد',
            'name_en': 'Fatima Saeed',
            'grade': 'الصف الأول',
            'grade_en': 'Grade 1',
            'school_id': 'sch_1',
            'avatar': 'https://example.com/avatar.jpg',
            'status': 'waiting',
            'bus': {
              'id': 'bus_101',
              'bus_number': '101',
              'bus_plate': '1234 A',
            }
          },
          {
            'id': '',
            'name': '',
            'name_en': '',
            'grade': 'الصف الثاني',
            'grade_en': 'Grade 2',
            'school_id': 'sch_1',
            'status': 'atSchool',
            'bus': {
              'id': 'bus_101',
              'bus_number': '101',
              'bus_plate': '1234 A',
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

      Student? tappedStudent;
      await tester.pumpWidget(buildTestableWidget(
        controller: controller,
        onChildDetailsPushed: (std) => tappedStudent = std,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('أحمد سعيد'), findsOneWidget);
      expect(find.text('فاطمة سعيد'), findsOneWidget);

      // Avatar fallback letters
      expect(find.text('أ'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);

      // Subtitles
      expect(find.text('الصف الثالث | مدرسة النور'), findsOneWidget);
      expect(find.text('الصف الأول | -'), findsOneWidget); // schoolName is null -> '-'

      // Tap on student 1
      await tester.tap(find.text('أحمد سعيد'));
      await tester.pumpAndSettle();

      expect(tappedStudent?.id, 'std_1');
      expect(find.text('Child Details Screen'), findsOneWidget);
    });
  });
}
