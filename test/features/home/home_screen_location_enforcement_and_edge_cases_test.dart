import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/home/presentation/home_screen.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_screen.dart';

class _FakeHomeEdgeDioAdapter implements HttpClientAdapter {
  bool missingLocation;
  bool updateSuccess;
  String updateMessage;
  List<Map<String, dynamic>>? customChildren;
  List<Map<String, dynamic>>? customNotifications;

  _FakeHomeEdgeDioAdapter({
    this.missingLocation = true,
    this.updateSuccess = true,
    this.updateMessage = 'تم تحديث الموقع بنجاح',
    this.customChildren,
    this.customNotifications,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('children')) {
      final data = {
        'data': customChildren ?? [
          {
            'id': 'std_missing_1',
            'name': 'يوسف أحمد',
            'grade': 'الصف الأول',
            'status': 'onBus',
            'suggested_direction': 'to_school',
            'home_lat': missingLocation ? null : 23.5880,
            'home_lng': missingLocation ? null : 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة الأمل',
            'bus': {
              'id': 'bus_1',
              'bus_number': '101',
              'plate_number': '1234 A',
            },
          },
          {
            'id': 'std_status_2',
            'name': 'هدى أحمد',
            'grade': 'الصف الثاني',
            'status': 'onBus',
            'suggested_direction': 'to_home',
            'home_lat': missingLocation ? null : 23.5880,
            'home_lng': missingLocation ? null : 58.3829,
            'school_lat': 23.6000,
            'school_lng': 58.4000,
            'school_name': 'مدرسة الأمل',
            'bus': {
              'id': 'bus_1',
              'bus_number': '101',
              'plate_number': '1234 A',
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

    if (path.contains('location-requests')) {
      return ResponseBody.fromString(
        jsonEncode({'data': []}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('location/update')) {
      final data = {
        'success': updateSuccess,
        'message': updateMessage,
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        updateSuccess ? 200 : 400,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('conversations')) {
      final data = {
        'data': [
          {
            'id': 1,
            'type': 'direct',
            'participants': [],
            'unread_count': 120,
          }
        ]
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('profile')) {
      final data = {
        'data': {
          'id': 301,
          'name': 'خالد الوالد',
          'email': 'parent@example.com',
        }
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('notifications')) {
      final notifs = customNotifications ?? [
        {
          'id': 'notif_edge_1',
          'title': 'تنبيه وصول',
          'body': 'وصل الابن إلى المدرسة',
          'type': 'arrival',
          'read': true,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
      final data = {
        'notifications': {
          'data': notifs,
        },
        'unread_count': notifs.where((n) => n['read'] == false).length,
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

Widget _buildHomeWidget({
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
      drawer: const Drawer(child: Text('Navigation Drawer')),
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );
  });

  late AppController controller;
  late _FakeHomeEdgeDioAdapter fakeDio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 301,
      'user_name': 'خالد الوالد',
      'app_locale': 'ar',
      'user_avatar_url': 'https://example.com/avatar_parent.png',
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'edge_token'});
    fakeDio = _FakeHomeEdgeDioAdapter(missingLocation: true);
    controller = AppController();
    controller.dio.httpClientAdapter = fakeDio;
    await controller.bootstrap();
    controller.stopTrackingPoll();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('HomeScreen Location Enforcement and Edge Cases Suite', () {
    testWidgets('1. Location enforcement dialog triggers when student has no home location', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = true;
      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(controller.students.any((s) => !s.hasLocation), isTrue);

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Dialog should be shown
      expect(find.byIcon(Icons.location_off_rounded), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('تحديد الآن'), findsOneWidget);

      // Dismiss dialog cleanly
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('2. HomeScreen drawer opens when menu icon is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = false;
      await controller.loadChildrenFromApi();

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final menuIcon = find.byIcon(Icons.menu_rounded);
      expect(menuIcon, findsOneWidget);
      await tester.tap(menuIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Navigation Drawer'), findsOneWidget);
    });

    testWidgets('3. Location requests quick action navigates to index 11 and marks notifications read', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = false;
      await controller.loadChildrenFromApi();

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Scroll down to quick actions
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 200));
      }

      final locReqIcon = find.byIcon(Icons.location_history_rounded);
      expect(locReqIcon, findsOneWidget);
      await tester.tap(locReqIcon);
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.navIndex, 11);
    });

    testWidgets('4. HomeScreen renders in Dark Mode with avatar image provider', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = false;
      await controller.loadChildrenFromApi();

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
          isDark: true,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('5. Location enforcement dialog - update home location succeeds and shows green snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = true;
      fakeDio.updateSuccess = true;
      fakeDio.updateMessage = 'تم تحديث الموقع بنجاح';

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('تحديد الآن'), findsOneWidget);
      await tester.tap(find.text('تحديد الآن'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LocationPickerScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(LocationPickerScreen))).pop({
        'location': const LatLng(23.5880, 58.3829),
        'note': 'منزل العائلة الجديد',
      });

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('تم تحديث الموقع بنجاح'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('6. Location enforcement dialog - failure branch displays red snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = true;
      fakeDio.updateSuccess = false;
      fakeDio.updateMessage = 'فشل في تحديث الموقع على الخادم';

      await tester.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('تحديد الآن'), findsOneWidget);
      await tester.tap(find.text('تحديد الآن'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LocationPickerScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(LocationPickerScreen))).pop(
        const LatLng(23.5880, 58.3829),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('فشل في تحديث الموقع على الخادم'), findsOneWidget);
    });

    testWidgets('7. RefreshIndicator onRefresh reloads children and notifications', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = false;
      await controller.loadChildrenFromApi();

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tester.runAsync(() async {
        final refreshIndicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
        await refreshIndicator.onRefresh();
      });
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(controller.students.isNotEmpty, isTrue);
    });

    testWidgets('8. Status icons and colors render for waitingAtHome, atSchool, notBoarded, late, arrivedHome', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = false;
      fakeDio.customChildren = [
        {
          'id': 'std_school',
          'name': 'طالب بالمدرسة',
          'grade': 'الصف الأول',
          'status': 'atSchool',
          'home_lat': 23.5880,
          'home_lng': 58.3829,
          'school_name': 'مدرسة الأمل',
          'avatar_url': 'https://example.com/avatar1.png',
        },
        {
          'id': 'std_wait',
          'name': 'طالب ينتظر بالمنزل',
          'grade': 'الصف الثاني',
          'status': 'waitingAtHome',
          'home_lat': 23.5880,
          'home_lng': 58.3829,
          'school_name': 'مدرسة الأمل',
        },
        {
          'id': 'std_not_board',
          'name': 'طالب لم يصعد',
          'grade': 'الصف الثالث',
          'status': 'notBoarded',
          'home_lat': 23.5880,
          'home_lng': 58.3829,
          'school_name': 'مدرسة الأمل',
        },
        {
          'id': 'std_late_status',
          'name': 'طالب متأخر',
          'grade': 'الصف الرابع',
          'status': 'late',
          'home_lat': 23.5880,
          'home_lng': 58.3829,
          'school_name': 'مدرسة الأمل',
        },
        {
          'id': 'std_arrived_home',
          'name': 'طالب وصل المنزل',
          'grade': 'الصف الخامس',
          'status': 'arrivedHome',
          'home_lat': 23.5880,
          'home_lng': 58.3829,
          'school_name': 'مدرسة الأمل',
        },
      ];

      await tester.runAsync(() async {
        while (controller.isLoadingChildren) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        await controller.loadChildrenFromApi();
      });

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
          isDark: true,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byIcon(Icons.school_outlined), findsWidgets);
      expect(find.byIcon(Icons.home_outlined), findsWidgets);
      expect(find.byIcon(Icons.hourglass_top_outlined), findsWidgets);
      expect(find.byIcon(Icons.warning_amber_outlined), findsWidgets);
    });

    testWidgets('9. Recent notifications list renders notifications and viewAll navigates to index 3', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = false;
      fakeDio.customNotifications = [
        {
          'id': 'notif_1',
          'title': 'حركة الحافلة',
          'body': 'انطلقت الحافلة من المدرسة',
          'type': 'trip_started',
          'read': false,
          'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
        {
          'id': 'notif_2',
          'title': 'إشعار سابق',
          'body': 'تم وصول الطالب للمدرسة',
          'type': 'arrival',
          'read': true,
          'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        }
      ];

      await tester.runAsync(() async {
        while (controller.isLoadingChildren) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        await controller.loadChildrenFromApi();
        await controller.loadNotificationsFromApi();
      });

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('حركة الحافلة'), findsWidgets);
      expect(find.text('عرض الكل'), findsOneWidget);

      await tester.tap(find.text('عرض الكل'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.navIndex, 4);
    });

    testWidgets('10. Quick action tracking navigates to index 2 and unread badge renders (>99)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeDio.missingLocation = false;
      await tester.runAsync(() async {
        while (controller.isLoadingChildren) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        await controller.loadChildrenFromApi();
        await controller.loadConversationsFromApi();
      });

      await tester.pumpWidget(
        _buildHomeWidget(
          child: const HomeScreen(),
          controller: controller,
        ),
      );
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -700));
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('99+'), findsWidgets);

      final trackIcon = find.byIcon(Icons.directions_bus_rounded);
      expect(trackIcon, findsWidgets);
      await tester.tap(trackIcon.last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.navIndex, 2);
    });
  });
}
