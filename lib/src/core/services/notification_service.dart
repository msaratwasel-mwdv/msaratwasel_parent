import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  developer.log(
    '📬 FCM [BG]: ${message.notification?.title} | data: ${message.data}',
    name: 'FCM',
  );

  // Initialize Firebase for the background isolate
  await Firebase.initializeApp();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final data = message.data;
  final String? cid = data['correlation_id']?.toString() ?? 
                     data['notification_id']?.toString() ?? 
                     data['message_id']?.toString() ?? 
                     message.messageId;

  // ── Persistent Deduplication ──────────────────────────────────────────
  if (cid != null) {
    final List<String> processedCids = prefs.getStringList('processed_cids') ?? [];
    if (processedCids.contains(cid)) {
      developer.log('♻️ [BG] Skipping persistent duplicate (CID: $cid)', name: 'FCM');
      return;
    }
    // Update the list
    processedCids.add(cid);
    if (processedCids.length > 100) processedCids.removeAt(0);
    await prefs.setStringList('processed_cids', processedCids);
  }

  // ── Security Check: Student Relationship ──────────────────────────────
  final targetStudentId = data['student_id']?.toString();
  if (targetStudentId != null) {
    final List<String> myStudentIds = prefs.getStringList('my_student_ids') ?? [];
    if (!myStudentIds.contains(targetStudentId)) {
      developer.log(
        '🛑 SECURITY [BG]: Suppressing notification for foreign student $targetStudentId',
        name: 'FCM',
      );
      return;
    }
  }


  // On Android, if the FCM message contains a `notification` object,
  // the system tray automatically displays it. We must NOT show a
  // second local notification, or the user sees duplicates.
  if (message.notification != null) {
    developer.log(
      '📬 FCM [BG]: System will auto-display notification, skipping local show',
      name: 'FCM',
    );
    return;
  }

  // Create local notification for data-only messages
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_notification');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );

  await localNotifications.initialize(initializationSettings);

  final String? savedLocale = prefs.getString('app_locale');
  final bool isEnglish = savedLocale == 'en';

  // ── Robust Content Extraction ──────────────────────────────────────────
  String? pick(List<dynamic> options) {
    for (final opt in options) {
      final str = opt?.toString();
      if (str != null && str.trim().isNotEmpty) return str;
    }
    return null;
  }

  final String titleAr = pick([data['title_ar'], data['title'], data['sender_name']]) ?? 'إشعار جديد';
  final String titleEn = pick([data['title_en'], data['titleEn'], data['sender_name_en'], data['title']]) ?? 'New Notification';
  final String bodyAr = pick([data['message_ar'], data['message'], data['body'], data['messagePreview']]) ?? '';
  final String bodyEn = pick([data['message_en'], data['messageEn'], data['body_en'], data['message'], data['body']]) ?? '';

  final String displayTitle = isEnglish ? titleEn : titleAr;
  final String displayBody = isEnglish ? bodyEn : bodyAr;

  if (displayTitle.isNotEmpty || displayBody.isNotEmpty) {
    String channelId = 'msarat_wasel_high_importance_v3';
    String channelName = 'إشعارات مسارات واصل الهامة';
    
    final type = data['type']?.toString();
    if (type == 'chat_message') {
      channelId = 'chat_messages_v3';
      channelName = 'رسائل المحادثات';
    } else if (type == 'admin_announcement') {
      channelId = 'school_announcements';
      channelName = 'إعلانات المدرسة';
    }

    await localNotifications.show(
      message.messageId.hashCode,
      displayTitle,
      displayBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
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
  /// Guard to prevent registering FCM listeners multiple times.
  /// init() may be called from both bootstrap() and login(), but
  /// listeners must only be attached ONCE.
  static bool _initialized = false;

  static OnNotificationReceived? get onReceived => _onReceived;

  // Notification Channel Constants
  static const String _channelId = 'msarat_wasel_high_importance_v4';
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

    // Always update the callback (login may set a fresh one)
    _onReceived = onNotificationReceived;

    // ─── GUARD: Only register listeners ONCE ─────────────────────────────
    // init() is called from both bootstrap() and login(). Firebase listeners
    // are additive — calling .listen() again adds a SECOND listener, causing
    // every notification to be processed twice. We register listeners only
    // on the first call and just update _onReceived on subsequent calls.
    if (_initialized) {
      developer.log(
        '✅ NotificationService: already initialized, updated callback only',
        name: 'FCM',
      );
      // Still return the token so login() can register it
      try {
        return await _fcm.getToken();
      } catch (e) {
        developer.log('❌ FCM: failed to get token: $e', name: 'FCM');
        return null;
      }
    }
    _initialized = true;

    // ── 1. Request Permissions ──────────────────────────────────────────
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Disable foreground notification banners handled by the OS.
    // We will show them manually via showLocalNotification to allow for 
    // intelligent deduplication and suppression (e.g. when already on chat screen).
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false, // 🚫 No OS banner in foreground
          badge: true,
          sound: true,
        );

    developer.log(
      '🔔 FCM permission: ${settings.authorizationStatus}',
      name: 'FCM',
    );

    // ── 2. Initialize Local Notifications ─────────────────────────────────
    const androidInit = AndroidInitializationSettings(
      'ic_notification',
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
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    const chatChannel = AndroidNotificationChannel(
      'chat_messages_v3',
      'رسائل المحادثات',
      description: 'إشعارات الرسائل الجديدة في المحادثات',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    const schoolChannel = AndroidNotificationChannel(
      'school_announcements',
      'إعلانات المدرسة',
      description: 'إشعارات وتنبيهات هامة من إدارة المدرسة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    const statusChannel = AndroidNotificationChannel(
      'student_status',
      'حالة الطلاب',
      description: 'إشعارات ركوب ونزول الطلاب',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    
    final plugin = _localNotif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (plugin != null) {
      await plugin.createNotificationChannel(androidChannel);
      await plugin.createNotificationChannel(chatChannel);
      await plugin.createNotificationChannel(schoolChannel);
      await plugin.createNotificationChannel(statusChannel);
    }

    // ── 4. Background Message Handler ──────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // ── 5. Foreground Message Handler (REGISTERED ONCE) ───────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📥 FCM RAW DATA: ${jsonEncode(message.data)}', name: 'FCM_RAW');
      
      final notification = AppNotification.fromFcm(message);
      developer.log('📦 MODEL CREATED: ID=${notification.id}, TitleEn=${notification.titleEn}', name: 'FCM_RAW');

      // Update app state (calls addNotification which handles dedup + popup)
      _onReceived?.call(notification, isTap: false);
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

  /// Displays a heads-up notification (banner) while the app is in the foreground.
  /// This is now called from AppController to ensure localized content (Ar/En) is used.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    int? id,
    String? payload,
    String? channelId,
    String? channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? _channelId,
      channelName ?? _channelName,
      channelDescription: _channelDesc,
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('launcher_icon'),
      color: const Color(0xFF062A5A),
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
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
      id ?? DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        
        AppNotification notification;
        
        // Detect payload format: toJson() has 'time' key, raw FCM data does not
        if (data.containsKey('time') && data.containsKey('read')) {
          // Structured payload from foreground showLocalNotification (via toJson)
          notification = AppNotification.fromJson(data);
        } else {
          // Raw FCM data payload from background handler
          notification = AppNotification.fromMap(data);
        }
        
        developer.log(
          '👆 Local Notification Tapped: ${notification.id} (Type: ${notification.type})',
          name: 'FCM',
        );
        
        // Notify the app about the tap event
        _onReceived?.call(notification, isTap: true);
      } catch (e, st) {
        developer.log('❌ Error parsing notification tap payload: $e', name: 'FCM', stackTrace: st);
      }
    }
  }
}
