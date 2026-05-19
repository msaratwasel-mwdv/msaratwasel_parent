import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

/// خدمة الاتصال بـ Laravel Reverb عبر WebSocket
/// تستقبل تحديثات حالة الطلاب فورياً بدون polling
class ReverbService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isDisposed = false;
  String? _lastSocketId; // حفظ آخر مُعرف سوكيت للمصادقة اللاحقة

  final int _userId;
  final Dio _dio;
  final void Function(Map<String, dynamic> data) _onStudentStatusUpdated;
  final void Function(Map<String, dynamic> data)? _onBusLocationUpdated;
  final void Function(Map<String, dynamic> data)? _onNotificationReceived;
  final void Function(Map<String, dynamic> data)? _onMessageReceived;

  // إعدادات Reverb المستمدة من AppConfig
  static const String _reverbKey = AppConfig.reverbKey;
  static String get _reverbHost => AppConfig.reverbHost;
  static int get _reverbPort => AppConfig.reverbPort;
  static bool get _isSecure => AppConfig.reverbUseSsl;

  // قائمة القنوات المشترك بها حالياً
  final Set<String> _subscribedChannels = {};
  final List<String> _pendingSubscriptions = [];

  ReverbService({
    required String token,
    required int userId,
    required Dio dio,
    required void Function(Map<String, dynamic> data) onStudentStatusUpdated,
    void Function(Map<String, dynamic> data)? onBusLocationUpdated,
    void Function(Map<String, dynamic> data)? onNotificationReceived,
    void Function(Map<String, dynamic> data)? onMessageReceived,
  }) : _userId = userId,
       _dio = dio,
       _onStudentStatusUpdated = onStudentStatusUpdated,
       _onBusLocationUpdated = onBusLocationUpdated,
       _onNotificationReceived = onNotificationReceived,
       _onMessageReceived = onMessageReceived;

  /// الاتصال بـ Reverb والاشتراك في القنوات المطلوبة
  Future<void> connect() async {
    if (_isDisposed) return;
    _subscribedChannels.clear();

    try {
      final protocol = _isSecure ? 'wss' : 'ws';
      final wsUrl = '$protocol://$_reverbHost:$_reverbPort/app/$_reverbKey';
      developer.log('🔌 Connecting to Reverb: $wsUrl', name: 'REVERB');

      try {
        FirebaseCrashlytics.instance.log('🔌 WebSocket connecting: $wsUrl');
        FirebaseCrashlytics.instance.setCustomKey('reverb_status', 'connecting');
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Reverb Connect: Attempting connection',
            category: 'reverb.connect',
            level: SentryLevel.info,
            data: {'url': wsUrl},
          ),
        );
      } catch (_) {}

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onDone: () {
          developer.log('🔌 WebSocket disconnected', name: 'REVERB');
          _isConnected = false;
          try {
            FirebaseCrashlytics.instance.log('🔌 WebSocket disconnected');
            FirebaseCrashlytics.instance.setCustomKey('reverb_status', 'disconnected');
            FirebaseAnalytics.instance.logEvent(name: 'reverb_disconnected');
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: WebSocket connection disconnected',
                category: 'reverb.disconnect',
                level: SentryLevel.warning,
              ),
            );
          } catch (_) {}
          _scheduleReconnect();
        },
        onError: (error) {
          developer.log('❌ WebSocket error: $error', name: 'REVERB');
          _isConnected = false;
          try {
            FirebaseCrashlytics.instance.log('❌ WebSocket error: $error');
            FirebaseCrashlytics.instance.recordError(error, null, reason: 'Reverb WebSocket Error');
            FirebaseCrashlytics.instance.setCustomKey('reverb_status', 'error');
            FirebaseAnalytics.instance.logEvent(
              name: 'reverb_error',
              parameters: {'error': error.toString()},
            );
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: WebSocket connection error',
                category: 'reverb.error',
                level: SentryLevel.error,
                data: {'error': error.toString()},
              ),
            );
            Sentry.captureException(
              error,
              withScope: (scope) {
                scope.setTag('service', 'reverb');
                scope.setTag('wsUrl', wsUrl);
              },
            );
          } catch (_) {}
          _scheduleReconnect();
        },
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_isConnected) {
          _send({'event': 'pusher:ping', 'data': {}});
        }
      });
    } catch (e, stack) {
      developer.log('❌ Failed to connect to Reverb: $e', name: 'REVERB');
      try {
        Sentry.captureException(e, stackTrace: stack);
      } catch (_) {}
      _scheduleReconnect();
    }
  }

  /// معالجة الرسائل الواردة من Reverb
  void _handleMessage(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final event = message['event'] as String?;

      switch (event) {
        case 'pusher:connection_established':
          _isConnected = true;
          final data = jsonDecode(message['data'] as String);
          final socketId = data['socket_id'] as String;
          _lastSocketId = socketId;
          developer.log('✅ Connected! Socket ID: $socketId', name: 'REVERB');

          try {
            FirebaseCrashlytics.instance.log('✅ Reverb Connected! Socket ID: $socketId');
            FirebaseCrashlytics.instance.setCustomKey('reverb_socket_id', socketId);
            FirebaseCrashlytics.instance.setCustomKey('reverb_status', 'connected');
            FirebaseAnalytics.instance.logEvent(
              name: 'reverb_connected',
              parameters: {'socket_id': socketId},
            );
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: Connection established',
                category: 'reverb.event',
                level: SentryLevel.info,
                data: {'socket_id': socketId},
              ),
            );
          } catch (_) {}

          // 1. الاشتراك في القنوات الخاصة بولي الأمر تلقائياً
          subscribe('private-guardian.$_userId', socketId);
          subscribe('private-App.Models.User.$_userId', socketId);

          // 2. معالجة الاشتراكات المعلقة
          if (_pendingSubscriptions.isNotEmpty) {
            final pending = List<String>.from(_pendingSubscriptions);
            _pendingSubscriptions.clear();
            for (final ch in pending) {
              subscribe(ch, socketId);
            }
          }
          break;

        case 'student.status.updated':
          developer.log('🔔 Event: student.status.updated', name: 'REVERB');
          try {
            FirebaseCrashlytics.instance.log('🔔 Reverb: student.status.updated');
            FirebaseAnalytics.instance.logEvent(name: 'reverb_student_status_updated');
          } catch (_) {}
          final data = _parseData(message['data']);
          try {
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb Event: student.status.updated',
                category: 'reverb.student',
                level: SentryLevel.info,
                data: data,
              ),
            );
          } catch (_) {}
          _onStudentStatusUpdated(data);
          break;

        case 'notification.pushed':
        case 'NotificationPushed':
          developer.log('🔔 Event: notification.pushed', name: 'REVERB');
          try {
            FirebaseCrashlytics.instance.log('🔔 Reverb: notification.pushed');
            FirebaseAnalytics.instance.logEvent(name: 'reverb_notification_pushed');
          } catch (_) {}
          final data = _parseData(message['data']);
          try {
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb Event: notification.pushed',
                category: 'reverb.notification',
                level: SentryLevel.info,
                data: data,
              ),
            );
          } catch (_) {}
          if (_onNotificationReceived != null) {
            _onNotificationReceived(data);
          }
          break;

        case 'driver.location.updated':
        case 'bus.location.updated':
        case 'BusLocationUpdated':
        case 'App\\Events\\BusLocationUpdated':
          developer.log('📍 Event: ${event}', name: 'REVERB');
          try {
            FirebaseCrashlytics.instance.log('📍 Reverb: driver/bus location updated');
            FirebaseAnalytics.instance.logEvent(name: 'reverb_bus_location_updated');
          } catch (_) {}
          final data = _parseData(message['data']);
          try {
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb Event: driver/bus location updated',
                category: 'reverb.location',
                level: SentryLevel.info,
                data: data,
              ),
            );
          } catch (_) {}
          if (_onBusLocationUpdated != null) {
            _onBusLocationUpdated(data);
          }
          break;

        case 'message.sent':
        case 'MessageSent':
        case 'App\\Events\\MessageSent':
          developer.log('💬 Event: message.sent', name: 'REVERB');
          try {
            FirebaseCrashlytics.instance.log('💬 Reverb: message.sent received');
            FirebaseAnalytics.instance.logEvent(name: 'reverb_chat_message_received');
          } catch (_) {}
          final data = _parseData(message['data']);
          try {
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb Event: message.sent',
                category: 'reverb.chat',
                level: SentryLevel.info,
                data: data,
              ),
            );
          } catch (_) {}
          if (_onMessageReceived != null) {
            _onMessageReceived(data);
          }
          break;

        case 'pusher_internal:subscription_succeeded':
          developer.log(
            '✅ Subscription succeeded for: ${message['channel']}',
            name: 'REVERB',
          );
          try {
            FirebaseCrashlytics.instance.log('📡 Reverb Subscribed: ${message['channel']}');
            FirebaseAnalytics.instance.logEvent(
              name: 'reverb_subscribed',
              parameters: {'channel': message['channel']?.toString() ?? ''},
            );
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: Subscription succeeded',
                category: 'reverb.subscription',
                level: SentryLevel.info,
                data: {'channel': message['channel']},
              ),
            );
          } catch (_) {}
          break;

        case 'pusher:pong':
          // Ignore heartbeat response
          break;

        default:
          if (event != null && !event.startsWith('pusher:')) {
            developer.log('❓ Unknown event: $event', name: 'REVERB');
            try {
              Sentry.addBreadcrumb(
                Breadcrumb(
                  message: 'Reverb: Unknown event received',
                  category: 'reverb.unknown',
                  level: SentryLevel.warning,
                  data: {'event': event, 'message': message},
                ),
              );
            } catch (_) {}
          }
          break;
      }
    } catch (e, stack) {
      developer.log('❌ Error parsing message: $e', name: 'REVERB');
      try {
        Sentry.captureException(
          e,
          stackTrace: stack,
          withScope: (scope) {
            scope.setTag('rawMessage', rawMessage.toString());
          },
        );
      } catch (_) {}
    }
  }

  Map<String, dynamic> _parseData(dynamic data) {
    if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  /// تنفيذ الاشتراك في قناة معينة (خاص أو عام)
  Future<void> subscribe(String channelName, [String? socketId]) async {
    if (_subscribedChannels.contains(channelName)) return;

    if (!_isConnected || _channel == null) {
      if (!_pendingSubscriptions.contains(channelName)) {
        _pendingSubscriptions.add(channelName);
        developer.log(
          '⏳ Subscription queued (not connected yet): $channelName',
          name: 'REVERB',
        );
      }
      return;
    }

    final effectiveSocketId = socketId ?? _lastSocketId;

    try {
      // إذا كانت قناة خاصة، نحتاج لمصادقة
      if (channelName.startsWith('private-')) {
        if (effectiveSocketId == null) {
          developer.log(
            '⚠️ Cannot subscribe to private channel $channelName without socketId',
            name: 'REVERB',
          );
          try {
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: Private subscription deferred (no socketId yet)',
                category: 'reverb.subscription',
                level: SentryLevel.warning,
                data: {'channel': channelName},
              ),
            );
          } catch (_) {}
          return;
        }
        final authData = await _authenticateChannel(
          channelName,
          effectiveSocketId,
        );
        _send({
          'event': 'pusher:subscribe',
          'data': {'channel': channelName, 'auth': authData['auth']},
        });
      } else {
        _send({
          'event': 'pusher:subscribe',
          'data': {'channel': channelName},
        });
      }
      _subscribedChannels.add(channelName);
      developer.log('📡 Subscribed to: $channelName', name: 'REVERB');
    } catch (e, stack) {
      developer.log(
        '❌ Subscription failed for $channelName: $e',
        name: 'REVERB',
      );
      try {
        Sentry.captureException(
          e,
          stackTrace: stack,
          withScope: (scope) {
            scope.setTag('channel', channelName);
            scope.setTag('socket_id', effectiveSocketId ?? 'none');
          },
        );
      } catch (_) {}
    }
  }

  /// إلغاء الاشتراك من قناة معينة
  void unsubscribe(String channelName) {
    if (!_subscribedChannels.contains(channelName)) return;

    try {
      _send({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channelName},
      });
      _subscribedChannels.remove(channelName);
      developer.log('🚫 Unsubscribed from: $channelName', name: 'REVERB');
      try {
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Reverb: Unsubscribed from channel',
            category: 'reverb.subscription',
            level: SentryLevel.info,
            data: {'channel': channelName},
          ),
        );
      } catch (_) {}
    } catch (e, stack) {
      developer.log(
        '❌ Unsubscription failed for $channelName: $e',
        name: 'REVERB',
      );
      try {
        Sentry.captureException(e, stackTrace: stack);
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _authenticateChannel(
    String channelName,
    String socketId,
  ) async {
    try {
      final response = await _dio.post(
        'broadcasting/auth',
        data: {'socket_id': socketId, 'channel_name': channelName},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Auth failed with status ${response.statusCode}');
    } catch (e, stack) {
      developer.log(
        '❌ Channel auth failed for $channelName: $e',
        name: 'REVERB',
      );
      try {
        Sentry.captureException(
          e,
          stackTrace: stack,
          withScope: (scope) {
            scope.setTag('channel', channelName);
            scope.setTag('socket_id', socketId);
          },
        );
      } catch (_) {}
      rethrow;
    }
  }

  /// إرسال رسالة عبر WebSocket
  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e, stack) {
      developer.log('❌ Failed to send: $e', name: 'REVERB');
      try {
        Sentry.captureException(
          e,
          stackTrace: stack,
          withScope: (scope) {
            scope.setTag('ws_action', 'send_payload');
          },
        );
      } catch (_) {}
    }
  }

  /// إعادة الاتصال تلقائياً بعد 5 ثوان
  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      developer.log('🔄 Reconnecting to Reverb...', name: 'REVERB');
      connect();
    });
  }

  /// إغلاق الاتصال نهائياً
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    developer.log('🔌 ReverbService disposed', name: 'REVERB');
  }
}
