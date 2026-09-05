import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/pages/request_absence_page.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/absence_request_page.dart' as alt_absence;
import 'package:msaratwasel_user/src/features/attendance/presentation/widgets/child_selector.dart';

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

class _CleanMockDioAdapter implements HttpClientAdapter {
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
          'success': true,
          'data': {
            'id': 101,
            'name': 'أحمد الوالد',
            'phone': '96812345678',
          }
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.path.contains('parent/children')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': [
            {
              'id': 'std_1',
              'name': 'عمر أحمد',
              'name_en': 'Omar Ahmed',
              'grade': 'الصف الرابع',
              'school': {'name': 'مدرسة النور'},
              'status': 'atHome',
            },
            {
              'id': 'std_2',
              'name': 'سارة أحمد',
              'name_en': 'Sara Ahmed',
              'grade': 'الصف الثاني',
              'school': {'name': 'مدرسة النور'},
              'status': 'atHome',
            },
          ]
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
  late AppController controller;
  late _CleanMockDioAdapter adapter;

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
      'my_student_ids': ['std_1', 'std_2'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    adapter = _CleanMockDioAdapter();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('Attendance & Absence Pages Deep Suite', () {
    testWidgets('1. RequestAbsencePage displays empty state when no students registered', (tester) async {
      adapter.responses['parent/children'] = {'success': true, 'data': []};

      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithAppScope(child: const RequestAbsencePage(), controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(RequestAbsencePage), findsOneWidget);
      expect(find.text('لا يوجد أبناء مسجلون'), findsOneWidget);
    });

    testWidgets('2. RequestAbsencePage selects student, absence type, date, reason, and submits successfully', (tester) async {
      adapter.responses['parent/absence-requests'] = {
        'success': true,
        'data': {'id': 1},
        'message': 'تم إرسال الطلب بنجاح',
      };

      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await controller.loadChildrenFromApi();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithAppScope(child: const RequestAbsencePage(), controller: controller));
      await tester.pumpAndSettle();

      // Check student cards are rendered
      expect(find.text('عمر أحمد'), findsOneWidget);
      expect(find.text('سارة أحمد'), findsOneWidget);

      // Select second student (سارة أحمد)
      await tester.tap(find.text('سارة أحمد'));
      await tester.pumpAndSettle();

      // Select absence type (عودة فقط)
      final returnOnly = find.text('عودة فقط');
      if (returnOnly.evaluate().isNotEmpty) {
        await tester.tap(returnOnly);
        await tester.pumpAndSettle();
      }

      // Enter reason in TextField
      final textFields = find.byType(TextField);
      expect(textFields, findsOneWidget);
      await tester.enterText(textFields.first, 'عذر طبي: مراجعة المستشفى');
      await tester.pumpAndSettle();
      expect(find.text('عذر طبي: مراجعة المستشفى'), findsOneWidget);

      // Tap submit button
      final submitBtn = find.widgetWithText(ElevatedButton, 'إرسال طلب الغياب');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Expect success snackbar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('تم إرسال طلب الغياب بنجاح'), findsOneWidget);
    });

    testWidgets('3. RequestAbsencePage displays error SnackBar on submission failure', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      // Override absence-requests endpoint to throw 400
      adapter.responses['parent/absence-requests'] = {
        'success': false,
        'message': 'لقد قمت بتقديم طلب غياب لهذا اليوم مسبقاً',
      };

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithAppScope(child: const RequestAbsencePage(), controller: controller));
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.widgetWithText(ElevatedButton, 'إرسال طلب الغياب');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // SnackBar should be displayed
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('4. AttendanceHistoryPage renders header, child selector, and summary cards', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithAppScope(child: const AttendanceHistoryPage(), controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceHistoryPage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);

      // Child selector should display students
      expect(find.text('عمر أحمد'), findsAtLeastNWidgets(1));

      // Scroll through calendar
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('5. ChildSelector widget handles child selection interaction', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final student1 = Student(
        id: 's1',
        name: 'عمر أحمد',
        nameEn: 'Omar Ahmed',
        grade: 'الصف الرابع',
        schoolId: 'sc1',
        status: StudentStatus.atHome,
        bus: const BusInfo(id: 'b1', number: '101', plate: 'ABC 101'),
      );

      final student2 = Student(
        id: 's2',
        name: 'سارة أحمد',
        nameEn: 'Sara Ahmed',
        grade: 'الصف الثاني',
        schoolId: 'sc1',
        status: StudentStatus.atHome,
        bus: const BusInfo(id: 'b1', number: '101', plate: 'ABC 101'),
      );

      Student? selected = student1;

      await tester.pumpWidget(
        _wrapWithAppScope(
          controller: controller,
          child: StatefulBuilder(
            builder: (context, setState) {
              return ChildSelector(
                children: [student1, student2],
                selectedChild: selected,
                onChildSelected: (child) {
                  setState(() {
                    selected = child;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChildSelector), findsOneWidget);
      expect(find.text('عمر أحمد'), findsAtLeastNWidgets(1));
      expect(find.text('سارة أحمد'), findsAtLeastNWidgets(1));

      // Tap second child
      await tester.tap(find.text('سارة أحمد').first);
      await tester.pumpAndSettle();
      expect(selected?.id, 's2');
    });

    testWidgets('6. Alternative AbsenceRequestPage renders form elements', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithAppScope(child: const alt_absence.AbsenceRequestPage(), controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(alt_absence.AbsenceRequestPage), findsOneWidget);
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'ملاحظات الغياب');
        await tester.pumpAndSettle();
        expect(find.text('ملاحظات الغياب'), findsOneWidget);
      }
    });

    testWidgets('7. Alternative AbsenceRequestPage validates missing date on submit', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithAppScope(child: const alt_absence.AbsenceRequestPage(), controller: controller));
      await tester.pumpAndSettle();

      final submitBtn = find.byType(ElevatedButton);
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('8. Alternative AbsenceRequestPage toggles absence types', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithAppScope(child: const alt_absence.AbsenceRequestPage(), controller: controller));
      await tester.pumpAndSettle();

      final typeCards = find.byWidgetPredicate((w) => w is InkWell && w.child is AnimatedContainer);
      if (typeCards.evaluate().length >= 3) {
        await tester.tap(typeCards.at(1)); // absenceIn
        await tester.pumpAndSettle();
        await tester.tap(typeCards.at(2)); // absenceOut
        await tester.pumpAndSettle();
        await tester.tap(typeCards.at(0)); // absenceFull
        await tester.pumpAndSettle();
      }

      expect(find.byType(alt_absence.AbsenceRequestPage), findsOneWidget);
    });

    testWidgets('9. AttendanceHistoryPage switches selected child', (tester) async {
      await tester.runAsync(() async {
        controller = AppController();
        controller.dio.httpClientAdapter = adapter;
        await controller.bootstrap();
        await Future.delayed(const Duration(milliseconds: 50));
        controller.stopTrackingPoll();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithAppScope(child: const AttendanceHistoryPage(), controller: controller));
      await tester.pumpAndSettle();

      final sara = find.text('سارة أحمد');
      if (sara.evaluate().isNotEmpty) {
        await tester.tap(sara.first);
        await tester.pumpAndSettle();
      }

      final omar = find.text('عمر أحمد');
      if (omar.evaluate().isNotEmpty) {
        await tester.tap(omar.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(AttendanceHistoryPage), findsOneWidget);
    });
  });
}
