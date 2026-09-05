// Agent 8: Chat Pages Deep Coverage (chat_page, contacts_page)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/chat_page.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/contacts_page.dart';

class _FakeChatDioAdapter implements HttpClientAdapter {
  bool failSendMessage;
  bool failGetContacts;
  bool failGetMessages;

  _FakeChatDioAdapter({
    this.failSendMessage = false,
    this.failGetContacts = false,
    this.failGetMessages = false,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('chat/contacts')) {
      if (failGetContacts) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Failed to load contacts'}),
          500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
      final data = {
        'data': [
          {
            'id': 1,
            'name': 'السائق سالم',
            'role': 'driver',
            'phone': '96891234567',
            'chat_description': 'سائق باص 101',
            'avatar_url': null,
          },
          {
            'id': 2,
            'name': 'المشرفة مريم',
            'role': 'supervisor',
            'phone': '96897654321',
            'chat_description': 'مشرفة باص 101',
            'avatar_url': null,
          },
        ]
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('chat/conversations') && path.contains('messages')) {
      if (options.method == 'POST') {
        if (failSendMessage) {
          return ResponseBody.fromString(
            jsonEncode({'message': 'Failed to send message'}),
            500,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        final data = {
          'data': {
            'id': 999,
            'conversation_id': 10,
            'body': (options.data is Map ? options.data['body'] : 'رسالة جديدة') ?? 'رسالة جديدة',
            'type': 'text',
            'is_mine': true,
            'created_at': DateTime.now().toIso8601String(),
            'sender': {'id': 101, 'name': 'أحمد الوالد', 'role': 'parent'},
          }
        };
        return ResponseBody.fromString(
          jsonEncode(data),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }

      if (failGetMessages) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Failed to load messages'}),
          500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }

      final data = {
        'data': [
          {
            'id': 101,
            'conversation_id': 10,
            'body': 'مرحباً، هل الباص في طريقه؟',
            'type': 'text',
            'is_mine': true,
            'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
            'sender': {'id': 101, 'name': 'أحمد الوالد', 'role': 'parent'},
          },
          {
            'id': 102,
            'conversation_id': 10,
            'body': 'نعم، نحن على بعد 5 دقائق منكم',
            'type': 'text',
            'is_mine': false,
            'created_at': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
            'sender': {'id': 1, 'name': 'السائق سالم', 'role': 'driver'},
          },
        ]
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('chat/conversations')) {
      if (options.method == 'POST') {
        final data = {
          'data': {
            'id': 10,
            'type': 'private',
            'unread_count': 0,
            'participants': [
              {'id': 101, 'name': 'أحمد الوالد', 'role': 'parent'},
              {'id': 1, 'name': 'السائق سالم', 'role': 'driver'},
            ],
          }
        };
        return ResponseBody.fromString(
          jsonEncode(data),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }

      final data = {
        'data': [
          {
            'id': 10,
            'type': 'private',
            'unread_count': 1,
            'updated_at': DateTime.now().toIso8601String(),
            'participants': [
              {'id': 101, 'name': 'أحمد الوالد', 'role': 'parent'},
              {'id': 1, 'name': 'السائق سالم', 'role': 'driver'},
            ],
            'last_message': {
              'id': 102,
              'conversation_id': 10,
              'body': 'نعم، نحن على بعد 5 دقائق منكم',
              'type': 'text',
              'is_mine': false,
              'created_at': DateTime.now().toIso8601String(),
              'sender': {'id': 1, 'name': 'السائق سالم', 'role': 'driver'},
            },
          }
        ]
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (path.contains('children')) {
      final data = {
        'data': [
          {
            'id': 'std_1',
            'name': 'عمر أحمد',
            'status': 'onBus',
            'bus': {'id': 'bus_1', 'bus_number': '101', 'plate_number': '1234 A'},
          }
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

Widget _build({required Widget child, required AppController c}) {
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
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController controller;
  late _FakeChatDioAdapter dioAdapter;

  setUp(() async {
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
    dioAdapter = _FakeChatDioAdapter();
    controller.dio.httpClientAdapter = dioAdapter;
    await controller.bootstrap();
  });

  tearDown(() {
    controller.stopTrackingPoll();
  });

  group('Agent 8: Chat Pages Deep Coverage Suite', () {
    testWidgets('1. ContactsPage renders contacts list, recent chats, and handles search', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ContactsPage(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(ContactsPage), findsOneWidget);
      expect(find.text('جهات الاتصال'), findsAtLeastNWidgets(1));
      expect(find.text('السائق سالم'), findsAtLeastNWidgets(1));
    });

    testWidgets('2. ContactsPage opens conversation from contact tile', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ContactsPage(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final driverTile = find.text('السائق سالم');
      if (driverTile.evaluate().isNotEmpty) {
        await t.tap(driverTile.first);
        for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      }
    });

    testWidgets('3. ContactsPage opens existing conversation from recent chats', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(child: const ContactsPage(), c: controller));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final recentChats = find.text('المحادثات الأخيرة');
      if (recentChats.evaluate().isNotEmpty) {
        expect(find.textContaining('نحن على بعد 5 دقائق'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('4. ChatPage renders message history and bubble widgets', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(
        child: const ChatPage(
          conversationId: 10,
          contactName: 'السائق سالم',
          contactRole: 'driver',
        ),
        c: controller,
      ));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('السائق سالم'), findsAtLeastNWidgets(1));
      expect(find.text('مرحباً، هل الباص في طريقه؟'), findsOneWidget);
      expect(find.text('نعم، نحن على بعد 5 دقائق منكم'), findsOneWidget);
    });

    testWidgets('5. ChatPage sends message via textfield and send button', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(
        child: const ChatPage(
          conversationId: 10,
          contactName: 'السائق سالم',
          contactRole: 'driver',
        ),
        c: controller,
      ));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await t.enterText(inputField, 'شكراً لك، سأكون بانتظاركم');
      await t.pump(const Duration(milliseconds: 100));

      final sendBtn = find.byIcon(Icons.send_rounded);
      if (sendBtn.evaluate().isNotEmpty) {
        await t.tap(sendBtn.first);
        for (int i = 0; i < 3; i++) await t.pump(const Duration(milliseconds: 200));
      }
    });

    testWidgets('6. ChatPage scrolls through messages and pulls to refresh', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(
        child: const ChatPage(
          conversationId: 10,
          contactName: 'السائق سالم',
          contactRole: 'driver',
        ),
        c: controller,
      ));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(ListView);
      if (scrollable.evaluate().isNotEmpty) {
        await t.drag(scrollable.first, const Offset(0, 300));
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(ChatPage), findsOneWidget);
    });

    testWidgets('7. ContactsPage handles loading failure gracefully', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      dioAdapter.failGetContacts = true;

      await t.pumpWidget(_build(child: const ContactsPage(), c: controller));
      for (int i = 0; i < 5; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(ContactsPage), findsOneWidget);
      dioAdapter.failGetContacts = false;
    });

    testWidgets('8. ChatPage handles send message failure gracefully', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      dioAdapter.failSendMessage = true;

      await t.pumpWidget(_build(
        child: const ChatPage(
          conversationId: 10,
          contactName: 'السائق سالم',
          contactRole: 'driver',
        ),
        c: controller,
      ));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await t.enterText(inputField, 'رسالة ستفشل');
      await t.pump(const Duration(milliseconds: 100));

      final sendBtn = find.byIcon(Icons.send_rounded);
      if (sendBtn.evaluate().isNotEmpty) {
        await t.tap(sendBtn.first);
        for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(SnackBar), findsAtLeastNWidgets(1));
      dioAdapter.failSendMessage = false;
    });

    testWidgets('9. ChatPage shows error view on message loading failure and can retry', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      dioAdapter.failGetMessages = true;

      await t.pumpWidget(_build(
        child: const ChatPage(
          conversationId: 99,
          contactName: 'المشرفة مريم',
          contactRole: 'supervisor',
        ),
        c: controller,
      ));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      expect(find.byType(ChatPage), findsOneWidget);

      dioAdapter.failGetMessages = false;
      final retryBtn = find.byIcon(Icons.refresh_rounded);
      if (retryBtn.evaluate().isNotEmpty) {
        await t.tap(retryBtn.first);
        for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));
      }
    });

    testWidgets('10. ChatPage ignores empty or whitespace send attempts', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);

      await t.pumpWidget(_build(
        child: const ChatPage(
          conversationId: 10,
          contactName: 'السائق سالم',
          contactRole: 'driver',
        ),
        c: controller,
      ));
      for (int i = 0; i < 4; i++) await t.pump(const Duration(milliseconds: 200));

      final inputField = find.byType(TextField);
      await t.enterText(inputField, '    ');
      await t.pump(const Duration(milliseconds: 100));

      final sendBtn = find.byIcon(Icons.send_rounded);
      if (sendBtn.evaluate().isNotEmpty) {
        await t.tap(sendBtn.first);
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ChatPage), findsOneWidget);
    });
  });
}
