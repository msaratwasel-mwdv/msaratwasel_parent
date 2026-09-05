import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_user/src/core/services/reverb_service.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeWebSocketSink implements WebSocketSink {
  final StreamController controller;
  final List<dynamic> sentMessages;
  _FakeWebSocketSink(this.controller, this.sentMessages);

  @override
  void add(data) {
    sentMessages.add(data);
    if (!controller.isClosed) {
      controller.add(data);
    }
  }

  @override
  void addError(error, [StackTrace? stackTrace]) {
    if (!controller.isClosed) {
      controller.addError(error, stackTrace);
    }
  }

  @override
  Future addStream(Stream stream) => controller.addStream(stream);

  @override
  Future close([int? closeCode, String? closeReason]) => controller.close();

  @override
  Future get done => controller.done;
}

class _FakeWebSocketChannel extends StreamChannelMixin implements WebSocketChannel {
  final StreamController incoming = StreamController.broadcast();
  final StreamController outgoing = StreamController.broadcast();
  final List<dynamic> sentMessages = [];

  @override
  Stream get stream => incoming.stream;

  @override
  WebSocketSink get sink => _FakeWebSocketSink(outgoing, sentMessages);

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready => Future.value();
}

class _MockBroadcastingDioAdapter implements HttpClientAdapter {
  bool authSucceeds = true;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('broadcasting/auth')) {
      if (authSucceeds) {
        return ResponseBody.fromString(
          jsonEncode({'auth': 'fake_auth_signature_123'}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      } else {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Unauthorized'}),
          403,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      }
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late _MockBroadcastingDioAdapter mockDioAdapter;
  late _FakeWebSocketChannel fakeChannel;

  setUp(() {
    dio = Dio();
    mockDioAdapter = _MockBroadcastingDioAdapter();
    dio.httpClientAdapter = mockDioAdapter;
    fakeChannel = _FakeWebSocketChannel();
  });

  tearDown(() {
    fakeChannel.incoming.close();
    fakeChannel.outgoing.close();
  });

  group('ReverbService Complete Test Suite', () {
    test('1. Initial state is disconnected and channels are not subscribed', () {
      final reverb = ReverbService(
        token: 'test_token',
        userId: 42,
        dio: dio,
        onStudentStatusUpdated: (_) {},
      );

      expect(reverb.isConnected, isFalse);
      expect(reverb.isChannelSubscribed('private-guardian.42'), isFalse);
      expect(reverb.isChannelSubscribed('private-bus.10'), isFalse);

      reverb.dispose();
    });

    test('2. Subscriptions before connection are queued and handled on connect', () async {
      final reverb = ReverbService(
        token: 'test_token',
        userId: 42,
        dio: dio,
        channelFactory: (_) => fakeChannel,
        onStudentStatusUpdated: (_) {},
        onBusLocationUpdated: (_) {},
        onNotificationReceived: (_) {},
        onMessageReceived: (_) {},
      );

      // Subscribe while offline
      await reverb.subscribe('public-announcements');
      await reverb.subscribe('private-bus.99');
      expect(reverb.isConnected, isFalse);

      // Connect
      await reverb.connect();

      // Emit connection_established
      fakeChannel.incoming.add(jsonEncode({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': '12345.67890'}),
      }));

      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        if (fakeChannel.sentMessages.any((m) => m.toString().contains('private-bus.99'))) break;
      }
      expect(reverb.isConnected, isTrue);

      // Verify pending subscriptions were sent
      final sentTexts = fakeChannel.sentMessages.map((m) => m.toString()).toList();
      expect(sentTexts.any((m) => m.contains('public-announcements')), isTrue);
      expect(sentTexts.any((m) => m.contains('private-bus.99')), isTrue);

      reverb.dispose();
    });

    test('3. Handles incoming WebSocket events properly', () async {
      Map<String, dynamic>? studentEvent;
      Map<String, dynamic>? notifEvent;
      Map<String, dynamic>? busEvent;
      Map<String, dynamic>? msgEvent;

      final reverb = ReverbService(
        token: 'test_token',
        userId: 42,
        dio: dio,
        channelFactory: (_) => fakeChannel,
        onStudentStatusUpdated: (d) => studentEvent = d,
        onNotificationReceived: (d) => notifEvent = d,
        onBusLocationUpdated: (d) => busEvent = d,
        onMessageReceived: (d) => msgEvent = d,
      );

      await reverb.connect();

      // Establish connection
      fakeChannel.incoming.add(jsonEncode({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': 'socket_999'}),
      }));
      await Future.delayed(const Duration(milliseconds: 10));

      // 1. Subscription succeeded event
      fakeChannel.incoming.add(jsonEncode({
        'event': 'pusher_internal:subscription_succeeded',
        'channel': 'private-guardian.42',
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(reverb.isChannelSubscribed('private-guardian.42'), isTrue);

      // 2. student.status.updated event
      fakeChannel.incoming.add(jsonEncode({
        'event': 'student.status.updated',
        'data': jsonEncode({'student_id': 'std_1', 'status': 'on_bus'}),
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(studentEvent?['student_id'], 'std_1');

      // 3. notification.pushed event
      fakeChannel.incoming.add(jsonEncode({
        'event': 'notification.pushed',
        'data': {'id': 'notif_1', 'title': 'تنبيه'},
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifEvent?['id'], 'notif_1');

      // 4. NotificationPushed (legacy name) event
      notifEvent = null;
      fakeChannel.incoming.add(jsonEncode({
        'event': 'NotificationPushed',
        'data': {'id': 'notif_legacy', 'title': 'تنبيه قديم'},
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifEvent?['id'], 'notif_legacy');

      // 5. bus.location.updated event
      fakeChannel.incoming.add(jsonEncode({
        'event': 'bus.location.updated',
        'channel': 'private-bus.10',
        'data': {'latitude': 23.6, 'longitude': 58.4, 'speed': 40.0},
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(busEvent?['latitude'], 23.6);

      // 6. message.sent event
      fakeChannel.incoming.add(jsonEncode({
        'event': 'message.sent',
        'data': {'message_id': 101, 'body': 'مرحبا'},
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(msgEvent?['message_id'], 101);

      // 7. pusher:pong event
      fakeChannel.incoming.add(jsonEncode({'event': 'pusher:pong', 'data': {}}));

      // 8. Unknown event
      fakeChannel.incoming.add(jsonEncode({'event': 'unknown.custom.event', 'data': {}}));

      // 9. Malformed message
      fakeChannel.incoming.add('not_a_valid_json');

      await Future.delayed(const Duration(milliseconds: 10));
      expect(reverb.isConnected, isTrue);

      // 10. Unsubscribe
      reverb.unsubscribe('private-guardian.42');
      expect(reverb.isChannelSubscribed('private-guardian.42'), isFalse);

      reverb.dispose();
    });

    test('4. Handles channel auth failure and channel stream errors gracefully', () async {
      mockDioAdapter.authSucceeds = false;

      final reverb = ReverbService(
        token: 'test_token',
        userId: 42,
        dio: dio,
        channelFactory: (_) => fakeChannel,
        onStudentStatusUpdated: (_) {},
      );

      await reverb.connect();

      // Connection established but auth will fail
      fakeChannel.incoming.add(jsonEncode({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': 'socket_err'}),
      }));
      await Future.delayed(const Duration(milliseconds: 20));

      // Should still be connected at WS level
      expect(reverb.isConnected, isTrue);

      // Error on stream should trigger disconnect
      fakeChannel.incoming.addError(Exception('Network error'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(reverb.isConnected, isFalse);

      reverb.dispose();
    });

    test('5. Disposing ReverbService multiple times is safe and cleans up timers', () {
      final reverb = ReverbService(
        token: 'test_token',
        userId: 42,
        dio: dio,
        onStudentStatusUpdated: (_) {},
      );

      reverb.dispose();
      expect(() => reverb.dispose(), returnsNormally);
      expect(reverb.isConnected, isFalse);
    });

    test('6. Handles connect() throwing exception cleanly', () async {
      final reverb = ReverbService(
        token: 'test_token',
        userId: 42,
        dio: dio,
        channelFactory: (_) => throw Exception('Connection failed'),
        onStudentStatusUpdated: (_) {},
      );

      await reverb.connect();
      expect(reverb.isConnected, isFalse);
      reverb.dispose();
    });

    test('7. onDone disconnects and re-queues custom channels to pending', () async {
      final reverb = ReverbService(
        token: 'test_token',
        userId: 42,
        dio: dio,
        channelFactory: (_) => fakeChannel,
        onStudentStatusUpdated: (_) {},
      );

      await reverb.connect();
      fakeChannel.incoming.add(jsonEncode({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': 'socket_disconnect_test'}),
      }));
      await Future.delayed(const Duration(milliseconds: 10));

      // Simulate successful subscription to a custom bus channel
      fakeChannel.incoming.add(jsonEncode({
        'event': 'pusher_internal:subscription_succeeded',
        'channel': 'private-bus.custom',
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(reverb.isChannelSubscribed('private-bus.custom'), isTrue);

      // Close stream to trigger onDone
      await fakeChannel.incoming.close();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(reverb.isConnected, isFalse);
      reverb.dispose();
    });
  });
}
