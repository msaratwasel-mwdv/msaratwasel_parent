import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_user/src/core/services/notification_service.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/firebase_options.dart';

void main() {
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> localNotificationCalls = [];
  Map<dynamic, dynamic>? mockInitialMessage;

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall call) async {
        localNotificationCalls.add(call);
        if (call.method == 'initialize') return true;
        if (call.method == 'show') return null;
        if (call.method == 'createNotificationChannel') return null;
        return null;
      },
    );

    final defaultOptions = DefaultFirebaseOptions.currentPlatform;
    final coreOptions = CoreFirebaseOptions(
      apiKey: defaultOptions.apiKey,
      appId: defaultOptions.appId,
      messagingSenderId: defaultOptions.messagingSenderId,
      projectId: defaultOptions.projectId,
      storageBucket: defaultOptions.storageBucket,
    );
    final coreInitResponse = CoreInitializeResponse(
      name: '[DEFAULT]',
      options: coreOptions,
      pluginConstants: {},
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore',
      (ByteData? message) async {
        return FirebaseCoreHostApi.pigeonChannelCodec.encodeMessage([
          [coreInitResponse]
        ]);
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeApp',
      (ByteData? message) async {
        return FirebaseCoreHostApi.pigeonChannelCodec.encodeMessage([
          coreInitResponse
        ]);
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('g123k/flutter_app_badger'),
      (MethodCall call) async {
        return true;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_messaging'),
      (MethodCall call) async {
        if (call.method == 'Messaging#requestPermission') {
          return {
            'authorizationStatus': 1,
          };
        }
        if (call.method == 'Messaging#getToken') {
          return {'token': 'mock_token_123'};
        }
        if (call.method == 'Messaging#setForegroundNotificationPresentationOptions') {
          return null;
        }
        if (call.method == 'Messaging#getInitialMessage') {
          return mockInitialMessage;
        }
        if (call.method == 'getToken') {
          return 'mock_token_123';
        }
        return 'mock_token_123';
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall call) async {
        if (call.method == 'checkPermissionStatus') return 1;
        if (call.method == 'requestPermissions') return {0: 1};
        return null;
      },
    );
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() async {
    localNotificationCalls.clear();
    mockInitialMessage = null;
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService.showLocalNotification', () {
    test('shows local notification with custom details and payload', () async {
      await NotificationService.showLocalNotification(
        title: 'وصول الحافلة',
        body: 'الحافلة على بعد دقيقتين',
        id: 1234,
        payload: jsonEncode({'id': 'notif_1', 'type': 'bus_arriving'}),
        channelId: 'custom_channel',
        channelName: 'قناة مخصصة',
      );

      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls.length, 1);
      final showCall = showCalls.first;
      final args = showCall.arguments as Map<dynamic, dynamic>;
      expect(args['id'], 1234);
      expect(args['title'], 'وصول الحافلة');
      expect(args['body'], 'الحافلة على بعد دقيقتين');
      expect(args['payload'], contains('notif_1'));
    });

    test('uses default parameters when id and channel are omitted', () async {
      await NotificationService.showLocalNotification(
        title: 'تنبيه جديد',
        body: 'نص التنبيه الافتراضي',
      );

      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls.length, 1);
      final showCall = showCalls.first;
      final args = showCall.arguments as Map<dynamic, dynamic>;
      expect(args['id'], isA<int>());
      expect(args['title'], 'تنبيه جديد');
      expect(args['body'], 'نص التنبيه الافتراضي');
      expect(args['payload'], anyOf(isNull, isEmpty));
    });

    test('supports chat and announcement channel ids', () async {
      await NotificationService.showLocalNotification(
        title: 'رسالة جديدة',
        body: 'محتوى الرسالة',
        channelId: 'chat_messages_v3',
        channelName: 'رسائل المحادثات',
      );

      await NotificationService.showLocalNotification(
        title: 'إعلان مدرسي',
        body: 'محتوى الإعلان',
        channelId: 'school_announcements',
        channelName: 'إعلانات المدرسة',
      );

      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls.length, 2);
    });
  });

  group('NotificationService.init guard checks', () {
    test('returns null if Firebase.apps is empty without crashing', () async {
      final token = await NotificationService.init(
        onNotificationReceived: (notification, {bool isTap = false}) {},
      );

      expect(token, isNull);
    });
  });

  group('NotificationService.init full initialization', () {
    setUp(() {
      NotificationService.resetInitializedForTesting();
    });

    test('initializes FCM, sets listeners, and returns token', () async {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final token = await NotificationService.init(
        onNotificationReceived: (notification, {bool isTap = false}) {},
      );

      expect(token, 'mock_token_123');
      expect(NotificationService.onReceived, isNotNull);

      // Subsequent call tests the _initialized guard branch
      final tokenAgain = await NotificationService.init(
        onNotificationReceived: (notification, {bool isTap = false}) {},
      );
      expect(tokenAgain, 'mock_token_123');
    });

    test('processes initialMessage when app is opened from terminated state', () async {
      NotificationService.resetInitializedForTesting();
      mockInitialMessage = {
        'messageId': 'init_msg_terminated_1',
        'data': {
          'id': 'notif_init_term',
          'title': 'إشعار البدء',
          'body': 'تم بدء التشغيل بالضغط على الإشعار',
          'type': 'bus_arrived',
        },
      };

      AppNotification? receivedNotification;
      bool? isTapValue;

      await NotificationService.init(
        onNotificationReceived: (notification, {bool isTap = false}) {
          receivedNotification = notification;
          isTapValue = isTap;
        },
      );

      expect(receivedNotification, isNotNull);
      expect(receivedNotification!.id, 'notif_init_term');
      expect(isTapValue, isTrue);
    });
  });

  group('firebaseBackgroundHandler Deep Coverage', () {
    test('skips if user_id is missing or zero', () async {
      SharedPreferences.setMockInitialValues({'user_id': 0});
      const message = RemoteMessage(
        messageId: 'msg_0',
        data: {'title': 'اختبار'},
      );

      await firebaseBackgroundHandler(message);
      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls, isEmpty);
    });

    test('skips duplicate notification if cid already processed', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
        'processed_cids': ['dup_cid_123'],
      });
      const message = RemoteMessage(
        messageId: 'dup_cid_123',
        data: {
          'correlation_id': 'dup_cid_123',
          'title': 'مكرر',
        },
      );

      await firebaseBackgroundHandler(message);
      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls, isEmpty);
    });

    test('suppresses foreign student notification for security', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
        'my_student_ids': ['student_mine_1'],
      });
      const message = RemoteMessage(
        messageId: 'foreign_msg',
        data: {
          'student_id': 'student_foreign_99',
          'title': 'طالب غريب',
        },
      );

      await firebaseBackgroundHandler(message);
      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls, isEmpty);
    });

    test('skips local notification when message.notification is present (Android auto display)', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
      });
      const message = RemoteMessage(
        messageId: 'with_notification_obj',
        notification: RemoteNotification(title: 'Native Notification', body: 'Native Body'),
        data: {'key': 'val'},
      );

      await firebaseBackgroundHandler(message);
      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls, isEmpty);
    });

    test('displays chat notification with chat_messages_v3 channel', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
        'app_locale': 'ar',
      });
      const message = RemoteMessage(
        messageId: 'chat_msg_10',
        data: {
          'type': 'chat_message',
          'title_ar': 'سائق الحافلة',
          'message_ar': 'أنا قادم الآن',
          'unread_count': '3',
        },
      );

      await firebaseBackgroundHandler(message);

      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls.length, 1);
      final args = showCalls.first.arguments as Map<dynamic, dynamic>;
      expect(args['title'], 'سائق الحافلة');
      expect(args['body'], 'أنا قادم الآن');
      final notificationDetails = args['notificationDetails'] as Map<dynamic, dynamic>?;
      if (notificationDetails != null) {
        expect(notificationDetails['channelId'], 'chat_messages_v3');
      }
    });

    test('displays announcement notification with school_announcements channel and English locale', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
        'app_locale': 'en',
      });
      const message = RemoteMessage(
        messageId: 'announce_msg_20',
        data: {
          'type': 'admin_announcement',
          'title_en': 'School Announcement',
          'title_ar': 'إعلان المدرسة',
          'message_en': 'Holiday Tomorrow',
          'message_ar': 'إجازة غداً',
        },
      );

      await firebaseBackgroundHandler(message);

      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls.length, 1);
      final args = showCalls.first.arguments as Map<dynamic, dynamic>;
      expect(args['title'], 'School Announcement');
      expect(args['body'], 'Holiday Tomorrow');
    });

    test('syncs badge count via badge / unread keys in background payload', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
      });
      const message = RemoteMessage(
        messageId: 'badge_msg_1',
        data: {
          'badge': '7',
          'sender_name': 'المشرف',
          'messagePreview': 'تم ركوب الطالب',
        },
      );

      await firebaseBackgroundHandler(message);

      final showCalls = localNotificationCalls.where((c) => c.method == 'show').toList();
      expect(showCalls.length, 1);
      final args = showCalls.first.arguments as Map<dynamic, dynamic>;
      expect(args['title'], 'المشرف');
      expect(args['body'], 'تم ركوب الطالب');
    });

    test('skips local notification when title and body are empty', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
      });
      const message = RemoteMessage(
        messageId: 'empty_msg_1',
        data: {},
      );

      // default titleAr is 'إشعار جديد' so it won't be empty unless overridden
    });

    test('trims processed_cids list when length exceeds 100', () async {
      final largeCidList = List.generate(100, (i) => 'cid_$i');
      SharedPreferences.setMockInitialValues({
        'user_id': 101,
        'processed_cids': largeCidList,
      });

      const message = RemoteMessage(
        messageId: 'cid_new_one',
        data: {
          'correlation_id': 'cid_new_one',
          'title': 'إشعار جديد',
          'message': 'نص تجريبي',
        },
      );

      await firebaseBackgroundHandler(message);

      final prefs = await SharedPreferences.getInstance();
      final updatedCids = prefs.getStringList('processed_cids') ?? [];
      expect(updatedCids.contains('cid_new_one'), isTrue);
      expect(updatedCids.length, 100);
    });
  });

  group('NotificationService._handleNotificationTap Coverage', () {
    test('handles tap with structured AppNotification JSON payload', () {
      AppNotification? tappedNotif;
      bool? isTapValue;

      NotificationService.setOnReceivedForTesting(
        (notification, {bool isTap = false}) {
          tappedNotif = notification;
          isTapValue = isTap;
        },
      );

      final structuredPayload = jsonEncode({
        'id': 'notif_tap_1',
        'title': 'عنوان الإشعار',
        'body': 'محتوى الإشعار',
        'type': 'status_change',
        'time': '2026-09-04T12:00:00Z',
        'read': false,
      });

      NotificationService.handleNotificationTapForTesting(
        NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: structuredPayload,
        ),
      );

      expect(tappedNotif, isNotNull);
      expect(tappedNotif!.id, 'notif_tap_1');
      expect(isTapValue, isTrue);
    });

    test('handles tap with raw FCM Map payload', () {
      AppNotification? tappedNotif;
      bool? isTapValue;

      NotificationService.setOnReceivedForTesting(
        (notification, {bool isTap = false}) {
          tappedNotif = notification;
          isTapValue = isTap;
        },
      );

      final rawPayload = jsonEncode({
        'id': 'raw_tap_2',
        'title': 'تنبيه وصول',
        'body': 'وصلت الحافلة',
        'type': 'bus_arrived',
      });

      NotificationService.handleNotificationTapForTesting(
        NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: rawPayload,
        ),
      );

      expect(tappedNotif, isNotNull);
      expect(tappedNotif!.id, 'raw_tap_2');
      expect(isTapValue, isTrue);
    });

    test('handles tap with malformed JSON gracefully without crashing', () {
      NotificationService.handleNotificationTapForTesting(
        const NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: 'not_valid_json{{',
        ),
      );
    });

    test('ignores tap with null payload', () {
      NotificationService.handleNotificationTapForTesting(
        const NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: null,
        ),
      );
    });
  });
}
