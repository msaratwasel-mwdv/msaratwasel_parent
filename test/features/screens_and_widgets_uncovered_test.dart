import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/core/routing/app_router.dart';
import 'package:msaratwasel_user/src/features/absence/presentation/absence_management_screen.dart';
import 'package:msaratwasel_user/src/features/attendance/widgets/absence_sheet.dart';
import 'package:msaratwasel_user/src/features/auth/domain/entities/auth_user.dart';
import 'package:msaratwasel_user/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:msaratwasel_user/src/features/auth/data/repositories/auth_repository.dart';
import 'package:msaratwasel_user/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:msaratwasel_user/src/features/language/data/repositories/language_repository.dart';
import 'package:msaratwasel_user/src/features/language/domain/usecases/set_locale_usecase.dart';
import 'package:msaratwasel_user/src/features/language/presentation/language_selector_screen.dart';
import 'package:msaratwasel_user/src/features/students/presentation/child_detail_screen.dart';
import 'package:msaratwasel_user/src/features/students/presentation/child_list_screen.dart';
import 'package:msaratwasel_user/src/features/students/presentation/pages/child_detail_page.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/bus_tracking_screen.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/widgets/active_bus_selector.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/widgets/student_marker_widget.dart';

class _MockDioAdapter implements HttpClientAdapter {
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
            'school_name': 'مدرسة النور',
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
            'school_name': 'مدرسة النور',
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

    return ResponseBody.fromString(
      jsonEncode({'data': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockAuthRepo implements AuthRepository {
  @override
  Future<AuthUser> login({required String civilId, required String password}) async {
    return AuthUser(id: '1', name: 'Parent', role: 'parent', accessToken: 'mock_token');
  }

  @override
  Future<void> requestPasswordReset({required String phoneOrUsername}) async {}

  @override
  Future<void> updateLanguage(String languageCode) async {}
}

class _MockLanguageRepo implements LanguageRepository {
  String? currentLocale;

  @override
  Future<void> setLocale(String code) async {
    currentLocale = code;
  }

  @override
  Future<String?> getSavedLocale() async => currentLocale;
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
    builder: (context, materialChild) => AppScope(
      controller: controller,
      child: materialChild!,
    ),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 100,
      'user_name': 'Parent Test',
      'has_seen_onboarding': true,
      'app_locale': 'ar',
    });
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'mock_token',
    });

    controller = AppController();
    controller.dio.httpClientAdapter = _MockDioAdapter();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Uncovered Screens and Widgets Suite', () {
    testWidgets('1. ChildListScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ChildListScreen(), controller: controller),
      );
      await tester.pump();

      expect(find.byType(ChildListScreen), findsOneWidget);
      expect(find.text('Child list placeholder'), findsOneWidget);
    });

    testWidgets('2. ChildDetailScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ChildDetailScreen(), controller: controller),
      );
      await tester.pump();

      expect(find.byType(ChildDetailScreen), findsOneWidget);
      expect(find.text('Child detail placeholder'), findsOneWidget);
    });

    testWidgets('3. LanguageSelectorScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const LanguageSelectorScreen(), controller: controller),
      );
      await tester.pump();

      expect(find.byType(LanguageSelectorScreen), findsOneWidget);
      expect(find.text('Language selector placeholder'), findsOneWidget);
    });

    testWidgets('4. DashboardScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const DashboardScreen(), controller: controller),
      );
      await tester.pump();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Dashboard placeholder'), findsOneWidget);
    });

    testWidgets('5. AbsenceManagementScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const AbsenceManagementScreen(), controller: controller),
      );
      await tester.pump();

      expect(find.byType(AbsenceManagementScreen), findsOneWidget);
      expect(find.text('Absence management placeholder'), findsOneWidget);
    });

    testWidgets('6. BusTrackingScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const BusTrackingScreen(), controller: controller),
      );
      await tester.pump();

      expect(find.byType(BusTrackingScreen), findsOneWidget);
      expect(find.text('Bus tracking placeholder'), findsOneWidget);
    });

    testWidgets('7. StudentMarkerWidget renders with initials and custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                StudentMarkerWidget(name: 'Ali', color: Colors.blue),
                StudentMarkerWidget(name: 'Sara', imageUrl: 'https://example.com/avatar.png'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StudentMarkerWidget), findsNWidgets(2));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('8. ActiveBusSelector renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ActiveBusSelector(), controller: controller),
      );
      await tester.pump();

      expect(find.byType(ActiveBusSelector), findsOneWidget);
    });

    testWidgets('9. AppRouter initializes with controller', (tester) async {
      final router = AppRouter(controller);
      expect(router.controller, controller);
    });

    test('10. LoginUseCase calls repository correctly', () async {
      final repo = _MockAuthRepo();
      final useCase = LoginUseCase(repo);
      final result = await useCase(civilId: '12345678', password: 'password123');

      expect(result.id, '1');
      expect(result.name, 'Parent');
      expect(result.role, 'parent');
    });

    test('11. SetLocaleUseCase calls repository correctly', () async {
      final repo = _MockLanguageRepo();
      final useCase = SetLocaleUseCase(repo);
      await useCase('en');

      expect(repo.currentLocale, 'en');
    });

    testWidgets('12. showAbsenceSheet opens bottom sheet and displays fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showAbsenceSheet(ctx),
              child: const Text('Open Sheet'),
            ),
          ),
          controller: controller,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('13. ChildDetailPage renders full details for student', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(controller.students.length, 2);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildDetailPage(studentId: 'std_1'),
          controller: controller,
        ),
      );
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(ChildDetailPage), findsOneWidget);
      expect(find.text('عمر أحمد'), findsOneWidget);
      expect(find.textContaining('الصف الرابع'), findsOneWidget);
      expect(find.text('101'), findsOneWidget);
      expect(find.text('أحمد السائق'), findsOneWidget);
    });
  });
}
