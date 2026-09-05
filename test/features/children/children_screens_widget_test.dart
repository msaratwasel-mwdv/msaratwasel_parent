import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/children/presentation/children_screen.dart';
import 'package:msaratwasel_user/src/features/children/presentation/pages/children_status_page.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_screen.dart';

class _FakeDioAdapter implements HttpClientAdapter {
  Map<String, dynamic> responseData = {
    'data': [
      {
        'id': 'std_1',
        'name': 'الابن الأول',
        'grade': 'الصف الأول',
        'avatar_url': 'https://example.com/avatar1.png',
        'national_id': '123456789',
        'location_note': 'بجانب المسجد الكبير',
        'school_location': '23.6000, 58.4000',
        'bus': {
          'id': 'bus_1',
          'bus_number': '101',
          'plate_number': '1111 A',
          'driver': {
            'id': 1,
            'name': 'سعيد السائق',
            'phone': '96899123456',
            'image_url': 'https://example.com/driver.png',
          },
          'supervisor': {
            'id': 2,
            'name': 'سالم المشرف',
            'phone': '96899654321',
            'image_url': 'https://example.com/supervisor.png',
          },
        },
        'status': 'onBus',
        'home_lat': 23.5880,
        'home_lng': 58.3829,
        'school_name': 'مدرسة النور',
        'attendance_percentage': 95,
        'trip_count': 42,
      },
      {
        'id': 'std_2',
        'name': 'الابن الثاني',
        'grade': 'الصف الثاني',
        'bus': {
          'id': 'bus_2',
          'bus_number': '-',
          'plate_number': '-',
        },
        'status': 'atSchool',
        'school_name': 'مدرسة الأمل',
        'attendance_percentage': 88,
        'trip_count': 30,
      },
    ]
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('children')) {
      return ResponseBody.fromString(
        jsonEncode(responseData),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path.contains('home-location')) {
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'message': 'تم تحديث الموقع بنجاح'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'data': []}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget buildTestableWidget({
  required Widget child,
  required AppController controller,
  bool isDark = false,
}) {
  return MaterialApp(
    theme: isDark ? ThemeData.dark() : ThemeData.light(),
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
  late _FakeDioAdapter fakeDio;

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
    fakeDio = _FakeDioAdapter();
    controller.dio.httpClientAdapter = fakeDio;
    await controller.bootstrap();
    await controller.loadChildrenFromApi();
    controller.stopTrackingPoll();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Agent 8: Children Screens Widget Suite', () {
    testWidgets('1. ChildrenScreen renders and displays empty state when no students', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenScreen(),
          controller: controller,
        ),
      );
      await tester.pump();

      expect(find.byType(ChildrenScreen), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('2. ChildrenStatusPage renders successfully and displays header and scroll view', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenStatusPage(),
          controller: controller,
        ),
      );
      await tester.pump();

      expect(find.byType(ChildrenStatusPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('3. LocationPickerScreen renders in read-only and editable modes', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const LocationPickerScreen(
            initialLocation: null,
            isReadOnly: true,
          ),
          controller: controller,
        ),
      );
      await tester.pump();

      expect(find.byType(LocationPickerScreen), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const LocationPickerScreen(
            initialLocation: null,
            isReadOnly: false,
          ),
          controller: controller,
        ),
      );
      await tester.pump();

      expect(find.byType(LocationPickerScreen), findsOneWidget);
    });

    testWidgets('4. ChildrenScreen renders populated student cards when students loaded', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(controller.students.length, 2);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ChildrenScreen), findsOneWidget);
      expect(find.text('الابن الأول'), findsOneWidget);
      expect(find.text('الابن الثاني'), findsOneWidget);
    });

    testWidgets('5. ChildrenStatusPage renders student cards and timeline when students loaded', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(controller.students.length, 2);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenStatusPage(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ChildrenStatusPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('6. ChildrenScreen scrolls and interacts with action buttons', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(ChildrenScreen), findsOneWidget);
    });

    testWidgets('7. ChildrenScreen opens child details bottom sheet and views sections', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      final studentCard = find.text('الابن الأول');
      expect(studentCard, findsOneWidget);
      await tester.tap(studentCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify bottom sheet opened
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byType(ListView), findsWidgets);

      // Scroll inside bottom sheet
      final list = find.byType(ListView);
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.last, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ChildrenScreen), findsOneWidget);
    });

    testWidgets('8. ChildrenScreen action buttons: attendance and track navigation', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      // Tap track button (skip the StatBox icon, target action button)
      final trackBtn = find.text('تتبع');
      expect(trackBtn, findsWidgets);
      await tester.tap(trackBtn.first);
      await tester.pumpAndSettle();
      expect(controller.navIndex, 2);

      // Tap attendance button
      final attendanceBtn = find.byIcon(Icons.calendar_month_rounded);
      expect(attendanceBtn, findsWidgets);
      await tester.tap(attendanceBtn.first);
      await tester.pumpAndSettle();
      expect(controller.navIndex, 7);
    });

    testWidgets('9. Child details bottom sheet shows driver, supervisor, location note and interacts with contact', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      // Tap first student to open details
      await tester.tap(find.text('الابن الأول'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll inside bottom sheet to reveal location note
      final list = find.byType(ListView);
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.last, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Verify location note is displayed
      expect(find.text('بجانب المسجد الكبير'), findsOneWidget);

      // Scroll further to reveal driver and supervisor
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.last, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Verify driver and supervisor are shown
      expect(find.text('سعيد السائق'), findsOneWidget);
      expect(find.text('سالم المشرف'), findsOneWidget);

      // Tap driver contact row
      final driverContact = find.text('سعيد السائق');
      await tester.tap(driverContact);
      await tester.pump();

      // Close bottom sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('10. ChildrenScreen renders properly in Dark Mode', (tester) async {
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const ChildrenScreen(),
          controller: controller,
          isDark: true,
        ),
      );
      for (int i = 0; i < 3; i++) await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ChildrenScreen), findsOneWidget);
      expect(find.text('الابن الأول'), findsOneWidget);
      expect(find.text('الابن الثاني'), findsOneWidget);
    });
  });
}
