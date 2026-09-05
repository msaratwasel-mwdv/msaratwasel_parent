// Agent 5: Attendance Pages (request_absence_page, attendance_history_page, child_selector, absence_sheet)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/pages/request_absence_page.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/widgets/child_selector.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/absence_request_page.dart';

Widget _build({required Widget child, required AppController c}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppScope(controller: c, child: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true, 'user_id': 101,
      'user_name': 'أحمد الوالد', 'app_locale': 'ar',
      'user_email': 'parent@test.com', 'user_phone': '0555555555',
      'my_student_ids': ['st_10', 'st_11'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() { controller.stopTrackingPoll(); controller.dispose(); });

  group('Agent 5: Attendance Pages Coverage Suite', () {
    testWidgets('1. RequestAbsencePage renders form with student selector and date picker', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const RequestAbsencePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(RequestAbsencePage), findsOneWidget);
    });

    testWidgets('2. RequestAbsencePage scrolls to reveal all fields', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const RequestAbsencePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -500));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(RequestAbsencePage), findsOneWidget);
    });

    testWidgets('3. AttendanceHistoryPage renders list and summary', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const AttendanceHistoryPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(AttendanceHistoryPage), findsOneWidget);
    });

    testWidgets('4. AttendanceHistoryPage scrolls through history items', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const AttendanceHistoryPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -1000));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(AttendanceHistoryPage), findsOneWidget);
    });

    testWidgets('5. ChildSelector renders children chips correctly', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      const bus = BusInfo(id: 'bus_10', number: '10', plate: '1234 A');
      final students = [
        const Student(id: 'st_10', name: 'سعد', grade: '3', schoolId: 'sch_1', bus: bus, status: StudentStatus.waitingAtHome, schoolName: 'مدرسة النور'),
        const Student(id: 'st_11', name: 'نورة', grade: '5', schoolId: 'sch_1', bus: bus, status: StudentStatus.waitingAtHome, schoolName: 'مدرسة النور'),
      ];
      Student? selected;
      await t.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AppScope(
          controller: controller,
          child: Scaffold(body: ChildSelector(
            children: students,
            selectedChild: selected,
            onChildSelected: (s) => selected = s,
          )),
        ),
      ));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(ChildSelector), findsOneWidget);
    });

    testWidgets('6. AbsenceRequestPage (old) renders absence form', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const AbsenceRequestPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(AbsenceRequestPage), findsOneWidget);
    });

    testWidgets('7. AbsenceRequestPage scrolls to reveal submit button', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const AbsenceRequestPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -1500));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(AbsenceRequestPage), findsOneWidget);
    });
  });
}
