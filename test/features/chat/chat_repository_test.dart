import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/chat/data/repositories/chat_repository.dart';

void main() {
  late Dio dio;
  late FakeChatAdapter adapter;
  late ChatRepository repository;

  setUp(() {
    adapter = FakeChatAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://test.wasel.com/api/'));
    dio.httpClientAdapter = adapter;
    repository = ChatRepository(dio: dio);
  });

  group('ChatRepository API Suite', () {
    test('1. getContacts returns list of ChatContact on 200', () async {
      adapter.handler = (options) {
        expect(options.path, contains('chat/contacts'));
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {
                'id': 10,
                'name': 'منى السائق',
                'role': 'driver',
                'phone': '0501112233',
                'chat_description': 'سائق باص 2',
              }
            ]
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final contacts = await repository.getContacts();
      expect(contacts.length, 1);
      expect(contacts.first.id, 10);
      expect(contacts.first.name, 'منى السائق');
      expect(contacts.first.role, 'driver');
    });

    test('2. getContacts throws Exception on DioException', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Unauthorized'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      expect(() => repository.getContacts(), throwsException);
    });

    test('3. getConversations returns list of ChatConversation with participants and lastMessage', () async {
      adapter.handler = (options) {
        expect(options.path, contains('chat/conversations'));
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {
                'id': 7,
                'type': 'private',
                'participants': [
                  {'id': 1, 'name': 'ولي الأمر', 'role': 'guardian'},
                  {'id': 2, 'name': 'المشرفة سارة', 'role': 'supervisor'},
                ],
                'unread_count': 1,
                'last_message': {
                  'id': 50,
                  'conversation_id': 7,
                  'sender': {'id': 2, 'name': 'المشرفة سارة', 'role': 'supervisor'},
                  'body': 'الباص قريب من المنزل',
                  'type': 'text',
                  'is_mine': false,
                  'created_at': '2026-09-04T08:10:00.000Z',
                }
              }
            ]
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final conversations = await repository.getConversations();
      expect(conversations.length, 1);
      expect(conversations.first.id, 7);
      expect(conversations.first.unreadCount, 1);
      expect(conversations.first.lastMessage?.body, 'الباص قريب من المنزل');
    });

    test('4. startConversation posts receiver_id and returns new conversation', () async {
      adapter.handler = (options) {
        expect(options.method, 'POST');
        expect(options.path, contains('chat/conversations'));
        expect((options.data as Map)['receiver_id'], 5);

        return ResponseBody.fromString(
          jsonEncode({
            'data': {
              'id': 88,
              'type': 'private',
              'participants': [
                {'id': 1, 'name': 'ولي الأمر', 'role': 'guardian'},
                {'id': 5, 'name': 'المشرفة', 'role': 'supervisor'},
              ],
              'unread_count': 0,
            }
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final conv = await repository.startConversation(5);
      expect(conv.id, 88);
      expect(conv.participants.length, 2);
    });

    test('5. sendMessage posts body and type to conversation endpoint', () async {
      adapter.handler = (options) {
        expect(options.method, 'POST');
        expect(options.path, contains('chat/conversations/88/messages'));
        final body = options.data as Map;
        expect(body['body'], 'سأكون بالانتظار');
        expect(body['type'], 'text');

        return ResponseBody.fromString(
          jsonEncode({
            'data': {
              'id': 101,
              'conversation_id': 88,
              'sender': {'id': 1, 'name': 'ولي الأمر', 'role': 'guardian'},
              'body': 'سأكون بالانتظار',
              'type': 'text',
              'is_mine': true,
              'created_at': '2026-09-04T08:15:00.000Z',
            }
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final message = await repository.sendMessage(88, 'سأكون بالانتظار');
      expect(message.id, 101);
      expect(message.body, 'سأكون بالانتظار');
      expect(message.isMine, isTrue);
    });

    test('6. getMessages returns message list for given conversation', () async {
      adapter.handler = (options) {
        expect(options.path, contains('chat/conversations/88/messages'));
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {
                'id': 101,
                'conversation_id': 88,
                'sender': {'id': 1, 'name': 'أنا', 'role': 'guardian'},
                'body': 'رسالة 1',
                'type': 'text',
                'created_at': '2026-09-04T08:00:00.000Z',
              },
              {
                'id': 102,
                'conversation_id': 88,
                'sender': {'id': 2, 'name': 'المشرفة', 'role': 'supervisor'},
                'body': 'رسالة 2',
                'type': 'text',
                'created_at': '2026-09-04T08:01:00.000Z',
              },
            ]
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final messages = await repository.getMessages(88);
      expect(messages.length, 2);
      expect(messages.first.body, 'رسالة 1');
      expect(messages.last.body, 'رسالة 2');
    });

    test('7. markAsRead completes silently and handles errors gracefully', () async {
      bool called = false;
      adapter.handler = (options) {
        called = true;
        expect(options.path, contains('chat/conversations/88/read'));
        return ResponseBody.fromString(
          jsonEncode({'status': 'ok'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await repository.markAsRead(88);
      expect(called, isTrue);

      // Verify that network failure in markAsRead does not throw (it logs and absorbs)
      adapter.handler = (options) => ResponseBody.fromString('Error', 500);
      await expectLater(repository.markAsRead(88), completes);
    });
  });
}

class FakeChatAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
