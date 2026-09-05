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
import 'package:msaratwasel_user/src/features/dashboard/presentation/root_shell.dart';
import 'package:msaratwasel_user/src/features/home/presentation/home_screen.dart';
import 'package:msaratwasel_user/src/features/children/presentation/children_screen.dart';
import 'package:msaratwasel_user/src/features/notifications/presentation/notifications_page.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/pages/bus_tracking_page.dart';
import 'package:msaratwasel_user/src/features/children/presentation/pages/children_status_page.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/contacts_page.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/pages/request_absence_page.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:msaratwasel_user/src/features/profile/presentation/parent_profile_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/more_page.dart';
import 'package:msaratwasel_user/src/features/absence/presentation/pages/absence_history_page.dart';
import 'package:msaratwasel_user/src/features/location_requests/presentation/pages/location_requests_page.dart';

class _CleanMockDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('profile')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {'id': 101, 'name': 'أحمد الوالد', 'phone': '96812345678'},
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

Widget _wrapRootShell({required Widget child, required AppController controller}) {
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
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;

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
    controller = AppController();
    controller.dio.httpClientAdapter = _CleanMockDioAdapter();
    await controller.bootstrap();
    controller.stopTrackingPoll();
  });

  tearDown(() {
    controller.stopTrackingPoll();
    controller.dispose();
  });

  group('RootShell & MissingLocationView Suite', () {
    testWidgets('1. RootShell initializes with HomeScreen at index 0', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapRootShell(child: const RootShell(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(RootShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('2. RootShell navigates between multiple tab indices dynamically', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapRootShell(child: const RootShell(), controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to index 1 (ChildrenScreen)
      controller.setNavIndex(1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChildrenScreen), findsOneWidget);

      // Switch to index 4 (NotificationsPage)
      controller.setNavIndex(4);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NotificationsPage), findsOneWidget);

      // Invalidate deep links if pendingNotificationId is set
      controller.setPendingNotificationId('notif_99');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NotificationsPage), findsOneWidget);

      // Switch back to 0
      controller.setNavIndex(0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('3. PopScope handles back navigation: moves back on non-zero index, shows snackbar on home', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapRootShell(child: const RootShell(), controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to tab 1
      controller.setNavIndex(1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.navIndex, 1);

      // Simulate pop on index 1 -> calls moveBack()
      final dynamic popScopeWidget = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      popScopeWidget.onPopInvokedWithResult(false, null);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.navIndex, 0);

      // Simulate pop on index 0 first time -> shows SnackBar
      final dynamic popScopeWidgetHome = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      popScopeWidgetHome.onPopInvokedWithResult(false, null);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('4. CustomDrawer renders user profile and items, triggers callbacks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int selectedIdx = -1;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppScope(
            controller: controller,
            child: child!,
          ),
          home: Scaffold(
            body: CustomDrawer(
              controller: controller,
              currentIndex: 0,
              onSelect: (idx) {
                selectedIdx = idx;
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomDrawer), findsOneWidget);
      expect(find.text('أحمد الوالد'), findsOneWidget);

      // Tap on a drawer item (e.g. Profile or Children)
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);
      await tester.tap(inkWells.first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(selectedIdx, 8); // Profile index
    });

    testWidgets('5. MissingLocationView renders student list without location and handles interaction', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final studentWithoutLoc = Student(
        id: 'std_missing',
        name: 'علي أحمد',
        nameEn: 'Ali Ahmed',
        grade: 'الصف الثالث',
        schoolId: 'sc1',
        status: StudentStatus.atHome,
        bus: const BusInfo(id: 'b1', number: '101', plate: 'ABC 101'),
        homeLocation: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppScope(
            controller: controller,
            child: child!,
          ),
          home: Scaffold(
            body: MissingLocationView(
              students: [studentWithoutLoc],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MissingLocationView), findsOneWidget);
      expect(find.text('علي أحمد'), findsOneWidget);
      expect(find.text('الصف الثالث'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // setNow button
      expect(find.byType(TextButton), findsOneWidget); // logout button
    });

    testWidgets('6. PopScope double press within 2s invokes SystemNavigator.pop', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool systemPopCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemNavigator.pop') {
          systemPopCalled = true;
        }
        return null;
      });

      await tester.pumpWidget(_wrapRootShell(child: const RootShell(), controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      final dynamic popScopeWidget = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      // First press -> shows SnackBar
      popScopeWidget.onPopInvokedWithResult(false, null);
      await tester.pump(const Duration(milliseconds: 100));
      expect(systemPopCalled, false);
      expect(find.byType(SnackBar), findsOneWidget);

      // Second press immediately (within 2s) -> invokes SystemNavigator.pop
      popScopeWidget.onPopInvokedWithResult(false, null);
      await tester.pump(const Duration(milliseconds: 100));
      expect(systemPopCalled, true);
    });

    testWidgets('7. CustomDrawer renders all drawer items and triggers callbacks with category marking', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final selectedIndices = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppScope(
            controller: controller,
            child: child!,
          ),
          home: Scaffold(
            body: CustomDrawer(
              controller: controller,
              currentIndex: 0,
              onSelect: (idx) {
                selectedIndices.add(idx);
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final icons = [
        Icons.home_rounded,
        Icons.family_restroom_rounded,
        Icons.directions_bus_rounded,
        Icons.timeline_rounded,
        Icons.notifications_active_rounded,
        Icons.chat_bubble_rounded,
        Icons.edit_calendar_rounded,
        Icons.history_rounded,
        Icons.assignment_turned_in_rounded,
        Icons.location_history_rounded,
        Icons.settings_rounded,
      ];

      for (final icon in icons) {
        final finder = find.byIcon(icon);
        if (finder.evaluate().isEmpty) {
          await tester.drag(find.byType(ListView), const Offset(0, -250));
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      expect(selectedIndices, [0, 1, 2, 3, 4, 5, 6, 7, 10, 11, 9]);
    });

    testWidgets('8. CustomDrawer logout button opens dialog and handles cancel / confirm', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppScope(
            controller: controller,
            child: child!,
          ),
          home: Scaffold(
            body: CustomDrawer(
              controller: controller,
              currentIndex: 0,
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final logoutBtn = find.byIcon(Icons.logout_rounded);
      expect(logoutBtn, findsOneWidget);

      // 1. Open dialog and tap cancel
      await tester.tap(logoutBtn);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AlertDialog), findsOneWidget);

      final cancelBtn = find.text('إلغاء');
      await tester.tap(cancelBtn);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AlertDialog), findsNothing);

      // 2. Open dialog and tap logout
      await tester.tap(logoutBtn);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AlertDialog), findsOneWidget);

      final confirmLogout = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'تسجيل الخروج'),
      );
      expect(confirmLogout, findsOneWidget);
      await tester.tap(confirmLogout);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('9. RootShell lazily builds multiple page indices (0..11 and fallback)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapRootShell(child: const RootShell(), controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      final indices = [2, 3, 5, 6, 7, 8, 9, 10, 11, 99];
      for (final idx in indices) {
        controller.setNavIndex(idx);
        await tester.pump(const Duration(milliseconds: 100));
        expect(controller.navIndex, idx);
      }
    });

    testWidgets('10. MissingLocationView with avatar and logout interaction', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final studentWithAvatar = Student(
        id: 'std_missing_avatar',
        name: 'فاطمة أحمد',
        nameEn: 'Fatima Ahmed',
        grade: 'الصف الخامس',
        schoolId: 'sc1',
        avatarUrl: 'https://example.com/fatima.jpg',
        status: StudentStatus.atHome,
        bus: const BusInfo(id: 'b1', number: '101', plate: 'ABC 101'),
        homeLocation: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppScope(
            controller: controller,
            child: child!,
          ),
          home: Scaffold(
            body: MissingLocationView(
              students: [studentWithAvatar],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('فاطمة أحمد'), findsOneWidget);

      final logoutBtn = find.widgetWithText(TextButton, 'تسجيل الخروج');
      if (logoutBtn.evaluate().isNotEmpty) {
        await tester.tap(logoutBtn);
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('11. CustomDrawer dark mode and active badge counts render', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      controller.updateAvatarUrl('https://example.com/avatar_test.jpg');

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
          builder: (context, child) => AppScope(
            controller: controller,
            child: child!,
          ),
          home: Scaffold(
            body: CustomDrawer(
              controller: controller,
              currentIndex: 2,
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomDrawer), findsOneWidget);
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('12. RootShell opens drawer and selection closes drawer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapRootShell(child: const RootShell(), controller: controller));
      await tester.pump(const Duration(milliseconds: 100));

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(scaffoldState.isDrawerOpen, true);

      final kidsItem = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('أبنائي'),
      );
      if (kidsItem.evaluate().isNotEmpty) {
        await tester.tap(kidsItem.first);
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(scaffoldState.isDrawerOpen, false);
        expect(controller.navIndex, 1);
      }
    });
  });
}
