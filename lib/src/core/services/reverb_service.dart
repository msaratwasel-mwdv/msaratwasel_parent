import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';

/// خدمة الاتصال بـ Laravel Reverb عبر WebSocket
/// تستقبل تحديثات حالة الطلاب فورياً بدون polling
class ReverbService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isDisposed = false;

  final String _token;
  final int _userId;
  final void Function(Map<String, dynamic> data) _onStudentStatusUpdated;

  // إعدادات Reverb
  static const String _reverbKey = 'wasel_key';
  static String get _reverbHost {
    // استخدام نفس host الخاص بالـ API (بدون /api/)
    final apiUrl = AppConfig.apiBaseUrl;
    final uri = Uri.parse(apiUrl);
    return uri.host;
  }
  static const int _reverbPort = 8080;

  ReverbService({
    required String token,
    required int userId,
    required void Function(Map<String, dynamic> data) onStudentStatusUpdated,
  })  : _token = token,
        _userId = userId,
        _onStudentStatusUpdated = onStudentStatusUpdated;

  /// الاتصال بـ Reverb والاشتراك في قناة ولي الأمر
  Future<void> connect() async {
    if (_isDisposed) return;

    try {
      final wsUrl = 'ws://$_reverbHost:$_reverbPort/app/$_reverbKey';
      developer.log('🔌 Connecting to Reverb: $wsUrl', name: 'REVERB');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // تأكد من تهيئة الاستماع داخل try/catch للتعامل مع أي استثناءات فورية
      try {
        _channel!.stream.listen(
          _handleMessage,
          onDone: () {
            developer.log('🔌 WebSocket disconnected', name: 'REVERB');
            _isConnected = false;
            _scheduleReconnect();
          },
          onError: (error) {
            developer.log('❌ WebSocket error (Stream): $error', name: 'REVERB');
            _isConnected = false;
            _scheduleReconnect();
          },
          cancelOnError: true,
        );
      } catch (e) {
        developer.log('❌ Exception in WebSocket stream: $e', name: 'REVERB');
        _scheduleReconnect();
      }

      // بدء Ping كل 30 ثانية للحفاظ على الاتصال
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_isConnected) {
          _send({'event': 'pusher:ping', 'data': {}});
        }
      });
    } catch (e) {
      developer.log('❌ Failed to connect to Reverb: $e', name: 'REVERB');
      _scheduleReconnect();
    }
  }

  /// معالجة الرسائل الواردة من Reverb
  void _handleMessage(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final event = message['event'] as String?;

      developer.log('📨 Reverb event: $event', name: 'REVERB');

      switch (event) {
        case 'pusher:connection_established':
          _isConnected = true;
          final data = jsonDecode(message['data'] as String);
          final socketId = data['socket_id'] as String;
          developer.log('✅ Connected! Socket ID: $socketId', name: 'REVERB');
          // الاشتراك في القناة الخاصة
          _subscribeToPrivateChannel(socketId);
          break;

        case 'pusher_internal:subscription_succeeded':
          developer.log('✅ Subscribed to guardian channel', name: 'REVERB');
          break;

        case 'pusher:pong':
          // Heartbeat response — ignore
          break;

        case 'pusher:error':
          developer.log('⚠️ Pusher error: ${message['data']}', name: 'REVERB');
          break;

        case 'student.status.updated':
          // الحدث المطلوب — تحديث حالة الطالب
          final data = message['data'] is String
              ? jsonDecode(message['data'] as String) as Map<String, dynamic>
              : message['data'] as Map<String, dynamic>;
          developer.log(
            '🔔 Student status updated: ${data['student_name']} → ${data['new_status']}',
            name: 'REVERB',
          );
          _onStudentStatusUpdated(data);
          break;

        default:
          developer.log('📨 Unhandled event: $event', name: 'REVERB');
      }
    } catch (e) {
      developer.log('❌ Error parsing message: $e', name: 'REVERB');
    }
  }

  /// الاشتراك في القناة الخاصة بولي الأمر (تتطلب مصادقة)
  Future<void> _subscribeToPrivateChannel(String socketId) async {
    final channelName = 'private-guardian.$_userId';

    try {
      // مصادقة القناة عبر backend
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      ));

      final response = await dio.post('broadcasting/auth', data: {
        'socket_id': socketId,
        'channel_name': channelName,
      });

      if (response.statusCode == 200) {
        final authData = response.data;
        final auth = authData['auth'] as String;

        // إرسال طلب الاشتراك مع التوقيع
        _send({
          'event': 'pusher:subscribe',
          'data': {'channel': channelName, 'auth': auth},
        });

        developer.log('📡 Subscribing to: $channelName', name: 'REVERB');
      }
    } catch (e) {
      developer.log('❌ Channel auth failed: $e', name: 'REVERB');
    }
  }

  /// إرسال رسالة عبر WebSocket
  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      developer.log('❌ Failed to send: $e', name: 'REVERB');
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
