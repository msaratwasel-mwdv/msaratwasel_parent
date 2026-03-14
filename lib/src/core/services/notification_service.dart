import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  developer.log(
    '📬 FCM [BG]: ${message.notification?.title} | data: ${message.data}',
    name: 'FCM',
  );
}

/// Callback type called whenever a push notification arrives.
typedef OnNotificationReceived = void Function(AppNotification notification);

/// Service responsible for initialising Firebase Cloud Messaging (FCM) and
/// bridging incoming push notifications into the app's state layer.
class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static OnNotificationReceived? _onReceived;

  /// Initialise FCM. Call once from [main] after Firebase.initializeApp().
  ///
  /// [onNotificationReceived] — called every time a relevant push arrives.
  /// Returns the FCM token to be registered with the backend.
  static Future<String?> init({
    required OnNotificationReceived onNotificationReceived,
  }) async {
    _onReceived = onNotificationReceived;

    // ── 1. طلب الإذن (Android 13+) ──────────────────────────────────────────
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    developer.log(
      '🔔 FCM permission: ${settings.authorizationStatus}',
      name: 'FCM',
    );

    // ── 2. تهيئة الإشعارات المحلية (لعرض الإشعار في الـ Foreground) ─────────
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        developer.log('👆 Local notification tapped: ${details.payload}', name: 'FCM');
      },
    );

    // ── 3. إعداد القناة لـ Android (مطلوب Android 8+) ──────────────────────
    const androidChannel = AndroidNotificationChannel(
      'msarat_wasel_channel', // id
      'مسارات واصل', // name
      description: 'إشعارات تطبيق مسارات واصل',
      importance: Importance.max,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // ── 4. معالج الإشعارات في الخلفية ──────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // ── 5. معالج الإشعارات عند فتح التطبيق (Foreground) ────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '📬 FCM [FG]: ${message.notification?.title} | data: ${message.data}',
        name: 'FCM',
      );

      // عرض الإشعار محلياً (لأن FCM لا يعرضه تلقائياً في الـ Foreground)
      final notification = message.notification;
      if (notification != null) {
        _localNotif.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }

      _handleRemoteMessage(message);
    });

    // ── 6. معالج النقر على الإشعار (من الخلفية) ─────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        '👆 FCM tapped from background: ${message.data}',
        name: 'FCM',
      );
      _handleRemoteMessage(message);
    });

    // ── 7. التحقق من إشعار فتح التطبيق لأول مرة ─────────────────────────────
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      developer.log('🚀 FCM: App opened from terminated via notification', name: 'FCM');
      _handleRemoteMessage(initialMessage);
    }

    // ── 8. الحصول على الـ FCM Token ──────────────────────────────────────────
    final token = await _fcm.getToken();
    developer.log('🔑 FCM Token = $token', name: 'FCM');

    // تحديث الـ Token عند تجديده
    _fcm.onTokenRefresh.listen((newToken) {
      developer.log('🔄 FCM Token refreshed = $newToken', name: 'FCM');
    });

    developer.log('✅ NotificationService: FCM initialised', name: 'FCM');
    return token;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Converts a Firebase [RemoteMessage] payload into [AppNotification].
  static void _handleRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final type = AppNotification.parseType(data['type'] as String?);

    final notification = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? data['title'] ?? '',
      body: message.notification?.body ?? data['body'] ?? '',
      type: type,
      time: DateTime.now(),
      data: data,
    );

    _onReceived?.call(notification);
  }
}
