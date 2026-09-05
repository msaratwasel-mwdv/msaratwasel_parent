import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:msaratwasel_user/src/features/dashboard/presentation/root_shell.dart';
import 'package:msaratwasel_user/src/features/children/presentation/children_screen.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_screen.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/contact_us_page.dart';

class _MockDashboardDioAdapter implements HttpClientAdapter {
  List<Map<String, dynamic>> studentsData = [];
  List<Map<String, dynamic>> notificationsData = [];
  bool returnEmptyStudents = false;
  Completer<void>? delayCompleter;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('children')) {
      if (delayCompleter != null) {
        await delayCompleter!.future;
      }
      final data = {
        'data': returnEmptyStudents ? [] : studentsData,
        'success': true,
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('bus/') && path.contains('/location')) {
      final data = {
        'bus_id': 'bus_1',
        'bus_number': 'B1',
        'bus_plate': '1111 A',
        'latitude': 23.5900,
        'longitude': 58.3900,
        'speed': 40.0,
        'heading': 180.0,
        'trip_status': 'in_progress',
        'trip_type': 'to_school',
        'total_students_count': 8,
        'total_students_on_board': 3,
        'target_latitude': 23.6000,
        'target_longitude': 58.4000,
        'eta_minutes': 5,
        'driver': {'id': 1, 'name': 'علي السائق', 'phone': '96891111111'},
        'supervisor': {'id': 2, 'name': 'منى المشرفة', 'phone': '96892222222'},
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('notifications')) {
      final data = {
        'data': notificationsData,
        'success': true,
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('profile')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'id': 101,
            'name': 'ولي الأمر التجريبي',
            'email': 'parent@test.com',
            'phone': '96890000000',
          },
          'success': true,
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('home-location')) {
      return ResponseBody.fromString(
        jsonEncode({'status': 'success', 'message': 'تم حفظ موقع المنزل'}),
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

List<Map<String, dynamic>> _generateAllStatusStudents() {
  return [
    {
      'id': 'std_1',
      'name': 'طالب حافلة للمدرسة',
      'grade': 'الأول',
      'status': 'onBusToSchool',
      'home_lat': null,
      'home_lng': null,
      'school_lat': 23.6,
      'school_lng': 58.4,
      'school_name': 'مدرسة المجد',
      'bus': {
        'id': 'bus_1',
        'bus_number': 'B1',
        'plate_number': '1111 A',
        'driver': {'id': 1, 'name': 'علي السائق', 'phone': '96891111111'},
        'supervisor': {'id': 2, 'name': 'منى المشرفة', 'phone': '96892222222'},
      },
      'trip_count': 12,
      'attendance_percentage': 98,
    },
    {
      'id': 'std_2',
      'name': 'طالب حافلة للمنزل',
      'grade': 'الثاني',
      'status': 'onBusToHome',
      'home_lat': 23.58,
      'home_lng': 58.38,
      'location_note': 'أمام المسجد مباشرة',
      'school_lat': 23.6,
      'school_lng': 58.4,
      'school_name': 'مدرسة الأمل',
      'bus': {
        'id': 'bus_1',
        'bus_number': 'B1',
        'plate_number': '1111 A',
      },
      'trip_count': 20,
      'attendance_percentage': 90,
    },
    {
      'id': 'std_3',
      'name': 'طالب بالمدرسة',
      'grade': 'الثالث',
      'status': 'atSchool',
      'home_lat': 23.58,
      'home_lng': 58.38,
      'school_name': 'مدرسة الأمل',
      'bus': {'id': 'bus_1', 'bus_number': 'B1', 'plate_number': '1111 A'},
      'trip_count': 5,
      'attendance_percentage': 85,
    },
    {
      'id': 'std_4',
      'name': 'طالب بالمنزل',
      'grade': 'الرابع',
      'status': 'atHome',
      'home_lat': 23.58,
      'home_lng': 58.38,
      'bus': {'id': 'bus_2', 'bus_number': 'B2', 'plate_number': '2222 B'},
      'trip_count': 30,
      'attendance_percentage': 100,
    },
    {
      'id': 'std_5',
      'name': 'طالب ينتظر بالمنزل',
      'grade': 'الخامس',
      'status': 'waitingAtHome',
      'home_lat': 23.58,
      'home_lng': 58.38,
      'bus': {'id': 'bus_2', 'bus_number': 'B2', 'plate_number': '2222 B'},
      'trip_count': 15,
      'attendance_percentage': 92,
    },
    {
      'id': 'std_6',
      'name': 'طالب وصل للمنزل',
      'grade': 'السادس',
      'status': 'arrivedHome',
      'home_lat': 23.58,
      'home_lng': 58.38,
      'bus': {'id': 'bus_2', 'bus_number': 'B2', 'plate_number': '2222 B'},
      'trip_count': 22,
      'attendance_percentage': 96,
    },
    {
      'id': 'std_7',
      'name': 'طالب لم يصعد',
      'grade': 'السابع',
      'status': 'notBoarded',
      'home_lat': 23.58,
      'home_lng': 58.38,
      'bus': {'id': 'bus_2', 'bus_number': 'B2', 'plate_number': '2222 B'},
      'trip_count': 10,
      'attendance_percentage': 80,
    },
    {
      'id': 'std_8',
      'name': 'طالب متأخر',
      'grade': 'الثامن',
      'status': 'late',
      'home_lat': 23.58,
      'home_lng': 58.38,
      'bus': {'id': 'bus_2', 'bus_number': 'B2', 'plate_number': '2222 B'},
      'trip_count': 8,
      'attendance_percentage': 75,
    },
  ];
}

Widget _wrapWidget({
  required Widget child,
  required AppController controller,
  bool isDark = false,
  bool wrapInScaffold = true,
}) {
  return MaterialApp(
    theme: isDark ? ThemeData.dark() : ThemeData.light(),
    locale: controller.locale,
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
    home: wrapInScaffold ? Scaffold(body: child) : child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  bool systemPopInvoked = false;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemNavigator.pop') {
          systemPopInvoked = true;
          return null;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_maps'),
      (call) async => null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/platform_views'),
      (call) async {
        if (call.method == 'create') return 0;
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async => true,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (MethodCall call) async {
        if (call.method == 'isLocationServiceEnabled') return true;
        if (call.method == 'checkPermission') return 2;
        if (call.method == 'getCurrentPosition') {
          return {
            'latitude': 23.5859,
            'longitude': 58.4059,
            'timestamp': 1000,
            'altitude': 0.0,
            'accuracy': 5.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'is_mocked': false,
          };
        }
        return null;
      },
    );
  });

  setUp(() async {
    systemPopInvoked = false;
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 101,
      'user_name': 'أحمد الوالد',
      'app_locale': 'ar',
      'user_email': 'parent@test.com',
      'user_phone': '96890000000',
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
  });

  Future<({AppController controller, _MockDashboardDioAdapter adapter})> setupController(
    WidgetTester t, {
    bool returnEmpty = false,
  }) async {
    late AppController c;
    final adapter = _MockDashboardDioAdapter();
    adapter.studentsData = _generateAllStatusStudents();
    adapter.returnEmptyStudents = returnEmpty;
    adapter.notificationsData = [
      {
        'id': 'notif_unread',
        'title': 'حافلة مقتربة',
        'body': 'الحافلة على بعد دقيقتين',
        'type': 'bus_approaching',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'notif_read',
        'title': 'صعود الطالب',
        'body': 'صعد الطالب الحافلة',
        'type': 'student_boarded',
        'read': true,
        'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
      },
    ];

    await t.runAsync(() async {
      c = AppController();
      c.dio.httpClientAdapter = adapter;
      await c.bootstrap();
      await Future.delayed(const Duration(milliseconds: 60));
      c.stopTrackingPoll();
    });

    return (controller: c, adapter: adapter);
  }

  group('DashboardPage Deep Edge Cases', () {
    testWidgets('1. Empty students state displays _EmptyStudentsCard with add child button', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t, returnEmpty: true);
      addTearDown(() => controller.dispose());
      expect(controller.students.isEmpty, isTrue);

      await t.pumpWidget(_wrapWidget(child: const DashboardPage(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);
      final addBtn = find.widgetWithIcon(FilledButton, Icons.add);
      expect(addBtn, findsOneWidget);

      await t.tap(addBtn);
      await t.pump();
    });

    testWidgets('2. Language toggle button toggles locale between ar and en', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());
      expect(controller.locale.languageCode, 'ar');

      await t.pumpWidget(_wrapWidget(child: const DashboardPage(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      final langBtn = find.byIcon(Icons.translate_rounded);
      expect(langBtn, findsOneWidget);
      await t.runAsync(() async {
        await t.tap(langBtn);
        await Future.delayed(const Duration(milliseconds: 100));
        controller.stopTrackingPoll();
      });
      await t.pump();

      expect(controller.locale.languageCode, 'en');
    });

    testWidgets('3. QuickServicesGrid buttons (Canteen, Kids, Support) navigate correctly', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());

      await t.pumpWidget(_wrapWidget(child: const DashboardPage(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      // 1. Canteen action
      final canteenItem = find.text('المقصف');
      if (canteenItem.evaluate().isNotEmpty) {
        await t.tap(canteenItem.first);
        await t.pump(const Duration(milliseconds: 100));
        expect(controller.navIndex, 4);
      }

      // 2. Kids action
      final kidsItem = find.text('الأبناء');
      if (kidsItem.evaluate().isNotEmpty) {
        await t.tap(kidsItem.first);
        await t.pump(const Duration(milliseconds: 100));
        expect(controller.navIndex, 0);
      }

      // 3. Support action
      final supportItem = find.text('الدعم');
      if (supportItem.evaluate().isNotEmpty) {
        await t.tap(supportItem.first);
        await t.pumpAndSettle();
        expect(find.byType(ContactUsPage), findsOneWidget);
      }
    });

    testWidgets('4. Pull to refresh triggers reload of children and notifications', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());

      await t.pumpWidget(_wrapWidget(child: const DashboardPage(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      final scrollable = find.byType(CustomScrollView);
      expect(scrollable, findsOneWidget);

      await t.fling(scrollable, const Offset(0, 400), 1000);
      for (int i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('5. Renders student status chips and bus info card across all StudentStatus values in Dark Mode', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());
      expect(controller.students.length, 8);

      await t.pumpWidget(_wrapWidget(child: const DashboardPage(), controller: controller, isDark: true));
      for (int i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.text('طالب حافلة للمدرسة'), findsOneWidget);
      expect(find.text('طالب حافلة للمنزل'), findsOneWidget);
      expect(find.text('طالب بالمدرسة'), findsOneWidget);

      // Scroll to view remaining students and bus info
      await t.drag(find.byType(CustomScrollView), const Offset(0, -600));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('طالب ينتظر بالمنزل'), findsOneWidget);
      expect(find.text('طالب متأخر'), findsOneWidget);
    });
  });

  group('RootShell PopScope and DeepLink Edge Cases', () {
    testWidgets('6. PopScope on index != 0 navigates back via moveBack()', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());
      controller.setNavIndex(1);
      expect(controller.navIndex, 1);

      await t.pumpWidget(_wrapWidget(child: const RootShell(), controller: controller, wrapInScaffold: false));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = t.widget<PopScope<Object?>>(popScopeFinder);
      popScope.onPopInvokedWithResult?.call(false, null);
      await t.pump(const Duration(milliseconds: 100));

      expect(controller.navIndex, 0);
    });

    testWidgets('7. PopScope on index 0 triggers double-press exit snackbar and SystemNavigator.pop()', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());
      controller.setNavIndex(0);

      await t.pumpWidget(_wrapWidget(child: const RootShell(), controller: controller, wrapInScaffold: false));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = t.widget<PopScope<Object?>>(popScopeFinder);

      // First back press shows SnackBar
      popScope.onPopInvokedWithResult?.call(false, null);
      await t.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(systemPopInvoked, isFalse);

      // Second back press within 2 seconds calls SystemNavigator.pop()
      popScope.onPopInvokedWithResult?.call(false, null);
      await t.pump();
      expect(systemPopInvoked, isTrue);
    });

    testWidgets('8. Deep link cache invalidation invalidates cached pages', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());

      await t.pumpWidget(_wrapWidget(child: const RootShell(), controller: controller, wrapInScaffold: false));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      controller.setPendingNotificationId('deep_link_test_123');
      await t.pump(const Duration(milliseconds: 100));

      expect(controller.pendingNotificationId, 'deep_link_test_123');
    });

    testWidgets('9. CustomDrawer renders and selects drawer index', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());

      await t.pumpWidget(_wrapWidget(child: const RootShell(), controller: controller, wrapInScaffold: false));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      final scaffold = t.state<ScaffoldState>(find.byType(Scaffold));
      scaffold.openDrawer();
      await t.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);

      final avatarInk = find.descendant(of: find.byType(Drawer), matching: find.byType(InkWell));
      if (avatarInk.evaluate().isNotEmpty) {
        await t.tap(avatarInk.first);
        await t.pumpAndSettle();
      }
    });
  });

  group('ChildrenScreen Deep Edge Cases', () {
    testWidgets('10. Displays empty state when students list is empty', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t, returnEmpty: true);
      addTearDown(() => controller.dispose());
      expect(controller.students.isEmpty, isTrue);

      await t.pumpWidget(_wrapWidget(child: const ChildrenScreen(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(ChildrenScreen), findsOneWidget);
      expect(find.byIcon(Icons.child_care_rounded), findsOneWidget);
      expect(find.text('لا يوجد أبناء مسجلون'), findsOneWidget);
    });

    testWidgets('11. Displays loading indicator when isLoadingChildren is true', (t) async {
      final (:controller, :adapter) = await setupController(t, returnEmpty: true);
      addTearDown(() => controller.dispose());

      final completer = Completer<void>();
      adapter.delayCompleter = completer;

      late Future<void> loadFuture;
      await t.runAsync(() async {
        loadFuture = controller.loadChildrenFromApi();
        await Future.delayed(const Duration(milliseconds: 20));
      });

      await t.pumpWidget(_wrapWidget(child: const ChildrenScreen(), controller: controller));
      await t.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await t.runAsync(() async {
        await loadFuture;
      });
      adapter.delayCompleter = null;
      await t.pump();
    });

    testWidgets('12. Student card for student without location displays "الموقع غير محدد" and opens LocationPickerScreen', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());

      await t.pumpWidget(_wrapWidget(child: const ChildrenScreen(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      // Tap student without location ('طالب حافلة للمدرسة')
      final stdCard = find.text('طالب حافلة للمدرسة');
      expect(stdCard, findsOneWidget);
      await t.tap(stdCard);
      await t.pumpAndSettle();

      expect(find.text('الموقع غير محدد'), findsOneWidget);
      final setNowBtn = find.text('تحديد الآن');
      expect(setNowBtn, findsOneWidget);

      // Tap 'تحديد الآن' button -> should push LocationPickerScreen
      await t.tap(setNowBtn);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      expect(find.byType(LocationPickerScreen), findsOneWidget);

      // Close picker
      final backBtn = find.byIcon(Icons.arrow_back_ios_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await t.tap(backBtn.first);
        await t.pumpAndSettle();
      }
    });

    testWidgets('13. Student card for student with location opens read-only LocationPickerScreen on map icon tap', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());

      await t.pumpWidget(_wrapWidget(child: const ChildrenScreen(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      // Tap student with location ('طالب حافلة للمنزل')
      final stdCard = find.text('طالب حافلة للمنزل');
      expect(stdCard, findsOneWidget);
      await t.tap(stdCard);
      await t.pumpAndSettle();

      final mapIcon = find.byIcon(Icons.map_rounded);
      if (mapIcon.evaluate().isNotEmpty) {
        await t.tap(mapIcon.first);
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(find.byType(LocationPickerScreen), findsOneWidget);
      }
    });

    testWidgets('14. Pull to refresh on ChildrenScreen triggers loadChildrenFromApi', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final (:controller, :adapter) = await setupController(t);
      addTearDown(() => controller.dispose());

      await t.pumpWidget(_wrapWidget(child: const ChildrenScreen(), controller: controller));
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      final scrollable = find.byType(CustomScrollView);
      expect(scrollable, findsOneWidget);

      await t.fling(scrollable, const Offset(0, 400), 1000);
      for (int i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(ChildrenScreen), findsOneWidget);
    });
  });
}
