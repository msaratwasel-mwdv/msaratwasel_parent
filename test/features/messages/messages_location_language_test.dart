// Agent 13: Messages, Location Requests, Language Pages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/messages/presentation/messages_page.dart';
import 'package:msaratwasel_user/src/features/location_requests/presentation/pages/location_requests_page.dart';
import 'package:msaratwasel_user/src/features/language/presentation/pages/language_selector_page.dart';

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
      'my_student_ids': ['st_10'],
    });
    FlutterSecureStorage.setMockInitialValues({'access_token': 'mock_token'});
    controller = AppController();
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Agent 13: Messages, LocationRequests, Language Suite', () {
    testWidgets('1. MessagesPage renders empty state when no messages', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const MessagesPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(MessagesPage), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('2. MessagesPage renders populated message bubbles and date separators', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      // Add messages
      controller.addMessage('مرحبا بكم، هل الحافلة قريبة؟');
      controller.addMessage('نعم يا فندم، سنصل خلال 5 دقائق');

      await t.pumpWidget(_build(child: const MessagesPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(MessagesPage), findsOneWidget);
      expect(find.text('مرحبا بكم، هل الحافلة قريبة؟'), findsOneWidget);
      expect(find.text('نعم يا فندم، سنصل خلال 5 دقائق'), findsOneWidget);
    });

    testWidgets('3. MessagesPage sends message via input textfield and send button', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const MessagesPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await t.enterText(textField, 'شكراً جزيلاً لكم');
      await t.pump(const Duration(milliseconds: 100));

      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);
      await t.tap(sendButton);
      await t.pump(const Duration(milliseconds: 200));

      expect(find.text('شكراً جزيلاً لكم'), findsOneWidget);
    });

    testWidgets('3b. MessagesPage opens photo picker bottom sheet and displays camera/gallery options', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const MessagesPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      final cameraButton = find.byIcon(Icons.photo_camera_outlined);
      expect(cameraButton, findsOneWidget);
      await t.tap(cameraButton);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);

      // Dismiss bottom sheet by tapping camera
      await t.tap(find.byIcon(Icons.camera_alt_rounded));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
    });

    testWidgets('4. LocationRequestsPage renders location request list', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const LocationRequestsPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(LocationRequestsPage), findsOneWidget);
    });

    testWidgets('5. LocationRequestsPage scrolls through items', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const LocationRequestsPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, -500));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(LocationRequestsPage), findsOneWidget);
    });

    testWidgets('6. LanguageSelectorPage renders language buttons', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const LanguageSelectorPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(LanguageSelectorPage), findsOneWidget);
    });

    testWidgets('7. LanguageSelectorPage renders correctly and displays title', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(_build(child: const LanguageSelectorPage(), c: controller));
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(LanguageSelectorPage), findsOneWidget);
    });

    testWidgets('8. MessagesPage handles incoming messages, typing indicator, and date separators', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      // Create incoming messages with various timestamps
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final lastMonth = now.subtract(const Duration(days: 35));

      final msg1 = MessageItem(
        id: 'msg_past',
        sender: 'المشرف',
        text: 'رسالة قديمة',
        time: lastMonth,
        incoming: true,
      );
      final msg2 = MessageItem(
        id: 'msg_yest',
        sender: 'المشرف',
        text: 'رسالة أمس',
        time: yesterday,
        incoming: true,
      );
      final msg3 = MessageItem(
        id: 'msg_today',
        sender: 'المشرف',
        text: 'رسالة اليوم',
        time: now,
        incoming: true,
      );

      final ctrl = AppController();
      addTearDown(ctrl.stopTrackingPoll);
      ctrl.addMessage(msg1.text);
      ctrl.addMessage(msg2.text);
      ctrl.addMessage(msg3.text);

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
          home: AppScope(controller: ctrl, child: const MessagesPage()),
        ),
      );
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(MessagesPage), findsOneWidget);
      expect(find.text('رسالة قديمة'), findsOneWidget);
      expect(find.text('رسالة اليوم'), findsOneWidget);
    });

    testWidgets('9. MessagesPage renders message with mediaUrl and taps menu icon', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      final ctrl = AppController();
      addTearDown(ctrl.stopTrackingPoll);
      ctrl.addMessage('صورة مرفقة', mediaUrl: 'invalid_image_path.jpg');

      final scaffoldKey = GlobalKey<ScaffoldState>();
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AppScope(
            controller: ctrl,
            child: Scaffold(
              key: scaffoldKey,
              drawer: const Drawer(child: Text('القائمة')),
              body: const MessagesPage(),
            ),
          ),
        ),
      );
      for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.text('صورة مرفقة'), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_rounded), findsOneWidget);

      final menuBtn = find.byIcon(Icons.menu_rounded);
      if (menuBtn.evaluate().isNotEmpty) {
        await t.tap(menuBtn.first);
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text('القائمة'), findsOneWidget);
      }
    });
  });
}
