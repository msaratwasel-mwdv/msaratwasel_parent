import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
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
typedef OnNotificationReceived = void Function(
  AppNotification notification, {
  bool isTap,
});

/// Service responsible for initialising Firebase Cloud Messaging (FCM) and
/// bridging incoming push notifications into the app's state layer.
class NotificationService {
  NotificationService._();

  static FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static OnNotificationReceived? _onReceived;

  // Notification Channel Constants
  static const String _channelId = 'msarat_wasel_high_importance_v2';
  static const String _channelName = 'إشعارات مسارات واصل الهامة';
  static const String _channelDesc = 'هذه القناة مخصصة لإشعارات الحافلات والرسائل الهامة';

  /// Initialise FCM. Call once from [main] after Firebase.initializeApp().
  ///
  /// [onNotificationReceived] — called every time a relevant push arrives.
  /// Returns the FCM token to be registered with the backend.
  static Future<String?> init({
    required OnNotificationReceived onNotificationReceived,
  }) async {
    // Check if Firebase is initialized
    if (Firebase.apps.isEmpty) {
      developer.log(
        '⚠️ NotificationService: Firebase not initialized. Skipping FCM setup.',
        name: 'FCM',
      );
      return null;
    }

    _onReceived = onNotificationReceived;

    // ── 1. Request Permissions ──────────────────────────────────────────
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Enable foreground notification banners on iOS
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    developer.log(
      '🔔 FCM permission: ${settings.authorizationStatus}',
      name: 'FCM',
    );

    // ── 2. Initialize Local Notifications ─────────────────────────────────
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Request permissions for iOS local notifications explicitly
    await _localNotif
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // ── 3. Setup Android Notification Channel ──────────────────────────────
    // we use a new ID 'v2' to bypass any previous silent settings on the device
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // ── 4. Background Message Handler ──────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // ── 5. Foreground Message Handler ──────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '📬 FCM [FG]: ${message.notification?.title} | data: ${message.data}',
        name: 'FCM',
      );

      final notification = AppNotification.fromFcm(message);
      
      // Update app state
      _onReceived?.call(notification, isTap: false);

      // Show local notification to guarantee banner/sound in foreground
      _showLocalNotification(notification);
    });

    // ── 6. Background Tap Handler ─────────────────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        '👆 FCM tapped from background: ${message.data}',
        name: 'FCM',
      );
      final notification = AppNotification.fromFcm(message);
      _onReceived?.call(notification, isTap: true);
    });

    // ── 7. Terminated State Tap Handler ───────────────────────────────────
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        '🚀 FCM: App opened from terminated via notification',
        name: 'FCM',
      );
      final notification = AppNotification.fromFcm(initialMessage);
      _onReceived?.call(notification, isTap: true);
    }

    // ── 8. Token Management ────────────────────────────────────────────────
    if (Platform.isIOS || Platform.isMacOS) {
      developer.log(
        '🍎 iOS/macOS detected: waiting for APNS token...',
        name: 'FCM',
      );
      String? apnsToken;
      int retryCount = 0;
      while (apnsToken == null && retryCount < 10) {
        apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          developer.log(
            '⏳ APNS token not ready yet, retrying ($retryCount/10)...',
            name: 'FCM',
          );
          await Future.delayed(const Duration(milliseconds: 500));
          retryCount++;
        }
      }
      if (apnsToken == null) {
        developer.log(
          '⚠️ Warning: APNS token still null after retries. getToken() might fail.',
          name: 'FCM',
        );
      } else {
        developer.log('✅ APNS token ready: $apnsToken', name: 'FCM');
      }
    }

    String? token;
    try {
      token = await _fcm.getToken();
      developer.log('🔑 FCM Token = $token', name: 'FCM');
    } catch (e) {
      developer.log('❌ FCM: failed to get token: $e', name: 'FCM');
    }

    _fcm.onTokenRefresh.listen((newToken) {
      developer.log('🔄 FCM Token refreshed = $newToken', name: 'FCM');
    });

    developer.log('✅ NotificationService: FCM initialised', name: 'FCM');
    return token;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<void> _showLocalNotification(AppNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      color: const Color(0xFF062A5A),
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound('default'),
      styleInformation: BigTextStyleInformation(notification.body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotif.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.toJson()),
    );
  }

  static void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final notification = AppNotification.fromJson(data);
        developer.log('👆 Local Notification Tapped: ${notification.id}', name: 'FCM');
        
        // Notify the app about the tap event
        _onReceived?.call(notification, isTap: true);
      } catch (e) {
        developer.log('❌ Error parsing notification tap payload: $e', name: 'FCM');
      }
    }
  }
}
