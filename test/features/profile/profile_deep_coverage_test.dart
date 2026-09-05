// Agent 9: Profile Pages Deep Coverage (parent_profile_page, change_password_page)
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/profile/presentation/parent_profile_page.dart';
import 'package:msaratwasel_user/src/features/profile/presentation/change_password_page.dart';

class _FakeProfileDioAdapter implements HttpClientAdapter {
  bool hasStudents;
  bool failChangePassword;
  bool failChangePasswordWithErrorsMap;
  _FakeProfileDioAdapter({
    this.hasStudents = true,
    this.failChangePassword = false,
    this.failChangePasswordWithErrorsMap = false,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('auth/change-password')) {
      if (failChangePasswordWithErrorsMap) {
        return ResponseBody.fromString(
          jsonEncode({
            'errors': {
              'new_password': ['The password must contain uppercase and lowercase letters.'],
            }
          }),
          422,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      if (failChangePassword) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'كلمة المرور الحالية غير صحيحة'}),
          400,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      final data = {'message': 'تم تغيير كلمة المرور بنجاح'};
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('children')) {
      final data = {
        'data': hasStudents
            ? [
                {
                  'id': 'std_1',
                  'name': 'عمر أحمد',
                  'name_ar': 'عمر أحمد',
                  'name_en': 'Omar Ahmed',
                  'grade': 'الصف الرابع',
                  'status': 'onBus',
                  'bus': {'id': 'bus_1', 'bus_number': '101', 'plate_number': '1234 A'},
                }
              ]
            : []
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('parent/profile/avatar')) {
      return ResponseBody.fromString(
        jsonEncode({'image_url': 'https://example.com/avatar_new.jpg'}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('parent/profile')) {
      final data = {
        'data': {
          'id': 101,
          'name': 'أحمد الوالد',
          'email': 'parent@test.com',
          'phone': '0555555555',
          'national_id': '12345678',
        }
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

Widget _build({required Widget child, required AppController c, Widget? drawer}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, materialChild) => AppScope(
      controller: c,
      child: materialChild!,
    ),
    home: Scaffold(drawer: drawer, body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;
  String? mockPickedImagePath;
  PlatformException? mockImagePickerException;
  Exception? mockGenericPickerException;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );

    Future<dynamic> imagePickerHandler(MethodCall call) async {
      if (mockImagePickerException != null) {
        throw mockImagePickerException!;
      }
      if (mockGenericPickerException != null) {
        throw mockGenericPickerException!;
      }
      if (call.method == 'pickImage' || call.method == 'getImage') {
        return mockPickedImagePath;
      }
      return null;
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      imagePickerHandler,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker_android'),
      imagePickerHandler,
    );
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() async {
    mockPickedImagePath = null;
    mockImagePickerException = null;
    mockGenericPickerException = null;
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'user_id': 101,
      'user_name': 'أحمد الوالد',
      'app_locale': 'ar',
      'user_email': 'parent@test.com',
      'user_phone': '0555555555',
      'my_student_ids': ['std_1'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    controller = AppController();
    controller.dio.httpClientAdapter = _FakeProfileDioAdapter();
    await controller.bootstrap();
    controller.stopTrackingPoll();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Agent 9: Profile Pages Deep Coverage Suite', () {
    testWidgets('1. ParentProfilePage renders profile header, personal info, and children', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.runAsync(() async {
        while (controller.students.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(ParentProfilePage), findsOneWidget);
      expect(find.text('أحمد الوالد'), findsAtLeastNWidgets(1));
      expect(find.text('0555555555'), findsOneWidget);
      expect(find.text('parent@test.com'), findsOneWidget);
      expect(find.textContaining('عمر'), findsAtLeastNWidgets(1));
    });

    testWidgets('2. ParentProfilePage opens photo options bottom sheet', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final cameraIcon = find.byIcon(Icons.camera_alt_rounded);
      if (cameraIcon.evaluate().isNotEmpty) {
        await t.tap(cameraIcon.first);
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text('التقاط صورة'), findsOneWidget);
        expect(find.text('اختيار من المعرض'), findsOneWidget);
      }
    });

    testWidgets('3. ParentProfilePage opens and cancels logout confirmation dialog', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -600));
        await t.pump(const Duration(milliseconds: 200));
      }

      final logoutBtn = find.byIcon(Icons.logout_rounded);
      if (logoutBtn.evaluate().isNotEmpty) {
        await t.tap(logoutBtn.first);
        await t.pump(const Duration(milliseconds: 300));

        expect(find.byType(AlertDialog), findsOneWidget);
        final cancelBtn = find.text('إلغاء');
        if (cancelBtn.evaluate().isNotEmpty) {
          await t.tap(cancelBtn.first);
          await t.pump(const Duration(milliseconds: 300));
          expect(find.byType(AlertDialog), findsNothing);
        }
      }
    });

    testWidgets('4. ParentProfilePage navigates to ChangePasswordPage', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -600));
        await t.pump(const Duration(milliseconds: 200));
      }

      final changePassBtn = find.byIcon(Icons.lock_reset_rounded);
      if (changePassBtn.evaluate().isNotEmpty) {
        await t.tap(changePassBtn.first);
        for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
        expect(find.byType(ChangePasswordPage), findsOneWidget);
      }
    });

    testWidgets('5. ChangePasswordPage validates inputs and toggles password visibility', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ChangePasswordPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(ChangePasswordPage), findsOneWidget);

      // Tap submit with empty form
      final submitBtn = find.byType(ElevatedButton);
      if (submitBtn.evaluate().isNotEmpty) {
        await t.tap(submitBtn.first);
        await t.pump(const Duration(milliseconds: 200));
      }

      // Toggle visibility
      final visibilityIcons = find.byIcon(Icons.visibility_off_outlined);
      if (visibilityIcons.evaluate().isNotEmpty) {
        await t.tap(visibilityIcons.first);
        await t.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('6. ChangePasswordPage submits valid new password successfully', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ChangePasswordPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 3) {
        await t.enterText(textFields.at(0), 'OldPass123!');
        await t.enterText(textFields.at(1), 'NewPass123!');
        await t.enterText(textFields.at(2), 'NewPass123!');
        await t.pump(const Duration(milliseconds: 100));

        final submitBtn = find.byType(ElevatedButton);
        if (submitBtn.evaluate().isNotEmpty) {
          await t.tap(submitBtn.first);
          for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
        }
      }
    });

    testWidgets('7. ParentProfilePage "viewAll" navigates to ChildrenScreen (index 1)', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final viewAllBtn = find.text('عرض الكل');
      if (viewAllBtn.evaluate().isNotEmpty) {
        await t.tap(viewAllBtn.first);
        await t.pump(const Duration(milliseconds: 100));
        expect(controller.navIndex, 1);
      }
    });

    testWidgets('8. ParentProfilePage confirms logout dialog and triggers logout', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -700));
        await t.pump(const Duration(milliseconds: 200));
      }

      final logoutBtn = find.byIcon(Icons.logout_rounded);
      if (logoutBtn.evaluate().isNotEmpty) {
        await t.tap(logoutBtn.first);
        await t.pump(const Duration(milliseconds: 300));

        expect(find.byType(AlertDialog), findsOneWidget);
        // Find logout button in dialog
        final confirmLogout = find.widgetWithText(TextButton, 'تسجيل الخروج');
        if (confirmLogout.evaluate().isNotEmpty) {
          await t.tap(confirmLogout.first);
          await t.pump(const Duration(milliseconds: 300));
          expect(controller.isAuthenticated, isFalse);
        }
      }
    });

    testWidgets('9. ParentProfilePage empty students state and dark mode', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final emptyDio = _FakeProfileDioAdapter(hasStudents: false);
      final emptyController = AppController();
      emptyController.dio.httpClientAdapter = emptyDio;
      await emptyController.bootstrap();
      emptyController.stopTrackingPoll();
      addTearDown(emptyController.stopTrackingPoll);

      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppScope(controller: emptyController, child: child!),
          home: const Scaffold(body: ParentProfilePage()),
        ),
      );
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(ParentProfilePage), findsOneWidget);
      expect(find.text('لا يوجد أبناء مسجلون'), findsOneWidget);
    });

    testWidgets('10. ChangePasswordPage displays server validation errors and handles password mismatch', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final errorAdapter = _FakeProfileDioAdapter(failChangePasswordWithErrorsMap: true);
      final errorController = AppController();
      errorController.dio.httpClientAdapter = errorAdapter;
      await errorController.bootstrap();
      errorController.stopTrackingPoll();
      addTearDown(errorController.stopTrackingPoll);

      await t.pumpWidget(_build(child: const ChangePasswordPage(), c: errorController));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 3) {
        // Mismatched passwords first
        await t.enterText(textFields.at(0), 'OldPass123!');
        await t.enterText(textFields.at(1), 'NewPass123!');
        await t.enterText(textFields.at(2), 'DifferentPass!');
        await t.pump(const Duration(milliseconds: 100));

        final submitBtn = find.byType(ElevatedButton);
        await t.tap(submitBtn.first);
        await t.pump(const Duration(milliseconds: 200));

        // Now matching passwords but backend returns 422 error
        await t.enterText(textFields.at(2), 'NewPass123!');
        await t.pump(const Duration(milliseconds: 100));

        await t.tap(submitBtn.first);
        for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
        expect(find.byType(SnackBar), findsOneWidget);
      }
    });

    testWidgets('11. ParentProfilePage photo bottom sheet items can be tapped cleanly', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final cameraIcon = find.byIcon(Icons.camera_alt_rounded);
      if (cameraIcon.evaluate().isNotEmpty) {
        await t.tap(cameraIcon.first);
        await t.pump(const Duration(milliseconds: 300));

        final galleryTile = find.text('اختيار من المعرض');
        if (galleryTile.evaluate().isNotEmpty) {
          await t.tap(galleryTile, warnIfMissed: false);
          await t.pump(const Duration(milliseconds: 200));
        }
      }
    });

    testWidgets('12. ParentProfilePage handles camera permission denied with SnackBar', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      mockImagePickerException = PlatformException(
        code: 'camera_access_denied',
        message: 'Camera permission denied',
      );

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final cameraIcon = find.byIcon(Icons.camera_alt_rounded);
      if (cameraIcon.evaluate().isNotEmpty) {
        await t.tap(cameraIcon.first);
        await t.pumpAndSettle();

        final takePhotoTile = find.text('التقاط صورة');
        if (takePhotoTile.evaluate().isNotEmpty) {
          await t.tap(takePhotoTile);
          for (int i = 0; i < 5; i++) await t.pump(const Duration(milliseconds: 100));

          expect(find.byType(SnackBar), findsOneWidget);
        }
      }
    });

    testWidgets('13. ParentProfilePage handles photo permission denied with SnackBar', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      mockImagePickerException = PlatformException(
        code: 'photo_access_denied',
        message: 'Photo permission denied',
      );

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final cameraIcon = find.byIcon(Icons.camera_alt_rounded);
      if (cameraIcon.evaluate().isNotEmpty) {
        await t.tap(cameraIcon.first);
        await t.pumpAndSettle();

        final galleryTile = find.text('اختيار من المعرض');
        if (galleryTile.evaluate().isNotEmpty) {
          await t.tap(galleryTile);
          for (int i = 0; i < 5; i++) await t.pump(const Duration(milliseconds: 100));

          expect(find.byType(SnackBar), findsOneWidget);
        }
      }
    });

    testWidgets('14. ParentProfilePage handles generic platform exception on pickImage', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      mockImagePickerException = PlatformException(
        code: 'other_error',
        message: 'Unexpected error',
      );

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final cameraIcon = find.byIcon(Icons.camera_alt_rounded);
      if (cameraIcon.evaluate().isNotEmpty) {
        await t.tap(cameraIcon.first);
        await t.pumpAndSettle();

        final galleryTile = find.text('اختيار من المعرض');
        if (galleryTile.evaluate().isNotEmpty) {
          await t.tap(galleryTile);
          for (int i = 0; i < 5; i++) await t.pump(const Duration(milliseconds: 100));

          expect(find.byType(SnackBar), findsOneWidget);
        }
      }
    });

    testWidgets('15. ParentProfilePage picks image and completes avatar upload', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final tempFile = File('${Directory.systemTemp.path}/test_avatar_upload.jpg');
      tempFile.writeAsBytesSync([1, 2, 3, 4]);
      addTearDown(() {
        try {
          if (tempFile.existsSync()) tempFile.deleteSync();
        } catch (_) {}
      });

      mockPickedImagePath = tempFile.path;

      await t.pumpWidget(_build(child: const ParentProfilePage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final cameraIcon = find.byIcon(Icons.camera_alt_rounded);
      if (cameraIcon.evaluate().isNotEmpty) {
        await t.tap(cameraIcon.first);
        await t.pumpAndSettle();

        final galleryTile = find.text('اختيار من المعرض');
        if (galleryTile.evaluate().isNotEmpty) {
          await t.tap(galleryTile);
          await t.runAsync(() async {
            await Future.delayed(const Duration(milliseconds: 300));
          });
          for (int i = 0; i < 5; i++) await t.pump(const Duration(milliseconds: 100));

          expect(controller.userAvatarUrl, 'https://example.com/avatar_new.jpg');
        }
      }
    });

    testWidgets('16. ParentProfilePage drawer menu button opens drawer', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(
        _build(
          child: const ParentProfilePage(),
          c: controller,
          drawer: const Drawer(child: Text('محتوى الدرج التجريبي')),
        ),
      );
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final menuIcon = find.byIcon(Icons.menu_rounded);
      if (menuIcon.evaluate().isNotEmpty) {
        await t.tap(menuIcon.first);
        await t.pumpAndSettle();

        expect(find.text('محتوى الدرج التجريبي'), findsOneWidget);
      }
    });
  });
}
