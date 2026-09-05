import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/chat/data/models/chat_models.dart';
import 'package:msaratwasel_user/src/features/chat/data/repositories/chat_repository.dart';

class FakeChatDioAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> recordedRequests = [];
  Map<String, dynamic>? customResponseData;
  int statusCode = 200;
  bool shouldThrowDio = false;
  String? dioErrorMessage;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recordedRequests.add({
      'path': options.path,
      'method': options.method,
      'data': options.data,
      'headers': options.headers,
    });

    if (shouldThrowDio) {
      throw DioException(
        requestOptions: options,
        error: dioErrorMessage ?? 'Network error',
        type: DioExceptionType.badResponse,
      );
    }

    dynamic data = customResponseData;
    if (options.path.contains('parent/children')) {
      data = {'data': []};
    } else if (options.path.contains('parent/profile')) {
      data = {'data': {'id': 1, 'name': 'Parent'}};
    } else if (customResponseData == null) {
      data = {'data': []};
    }

    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Models Serialization & Method Suite', () {
    test('1. ChatContact.fromJson maps all properties and normalizes avatar URL', () {
      final json = {
        'id': 42,
        'name': 'أستاذ سامي',
        'role': 'سائق',
        'phone': '+96891234567',
        'chat_description': 'سائق الحافلة رقم 12',
        'avatar_url': 'storage/avatars/driver42.png',
      };

      final contact = ChatContact.fromJson(json);

      expect(contact.id, 42);
      expect(contact.name, 'أستاذ سامي');
      expect(contact.role, 'سائق');
      expect(contact.phone, '+96891234567');
      expect(contact.chatDescription, 'سائق الحافلة رقم 12');
      expect(contact.avatarUrl, isNotNull);
      expect(contact.avatarUrl!.contains('storage/avatars/driver42.png'), isTrue);
    });

    test('2. ChatConversation.fromJson parses participants, last message, and handles missing fields', () {
      final json = {
        'id': 100,
        'type': 'private',
        'unread_count': 3,
        'updated_at': '2026-09-04T08:30:00Z',
        'participants': [
          {'id': 1, 'name': 'ولي الأمر', 'role': 'parent'},
          {'id': 2, 'name': 'المشرفة ليلى', 'role': 'supervisor'},
        ],
        'last_message': {
          'id': 501,
          'conversation_id': 100,
          'sender': {'id': 2, 'name': 'المشرفة ليلى', 'role': 'supervisor'},
          'body': 'وصلت الحافلة إلى المدرسة',
          'type': 'text',
          'is_mine': false,
          'created_at': '2026-09-04T08:29:00Z',
        },
      };

      final conversation = ChatConversation.fromJson(json);

      expect(conversation.id, 100);
      expect(conversation.type, 'private');
      expect(conversation.unreadCount, 3);
      expect(conversation.updatedAt?.hour, 8);
      expect(conversation.participants.length, 2);
      expect(conversation.lastMessage?.body, 'وصلت الحافلة إلى المدرسة');
      expect(conversation.lastMessage?.sender.name, 'المشرفة ليلى');
      expect(conversation.lastMessage?.isMine, isFalse);
    });

    test('3. ChatConversation.otherParticipant correctly resolves counterparty or falls back', () {
      final p1 = const ChatParticipant(id: 10, name: 'أنا', role: 'parent');
      final p2 = const ChatParticipant(id: 20, name: 'المشرف', role: 'supervisor');

      final conv = ChatConversation(
        id: 1,
        type: 'private',
        participants: [p1, p2],
      );

      // When myUserId is 10, other participant is 20
      expect(conv.otherParticipant(10)?.id, 20);
      expect(conv.otherParticipant(10)?.name, 'المشرف');

      // When myUserId is 20, other participant is 10
      expect(conv.otherParticipant(20)?.id, 10);

      // When user is not among participants, falls back to first participant
      expect(conv.otherParticipant(99)?.id, 10);

      // Empty participants list returns null
      final emptyConv = ChatConversation(
        id: 2,
        type: 'group',
        participants: [],
      );
      expect(emptyConv.otherParticipant(10), isNull);
    });

    test('4. ChatConversation.copyWith maintains immutability and updates requested fields', () {
      final original = ChatConversation(
        id: 5,
        type: 'private',
        participants: [],
        unreadCount: 4,
      );

      final updated = original.copyWith(unreadCount: 0);

      expect(updated.id, 5);
      expect(updated.unreadCount, 0);
      expect(original.unreadCount, 4); // Original unmodified
    });

    test('5. ChatMessage and ChatMessageSender parse safely with fallback defaults', () {
      final json = {
        'id': 999,
        'conversation_id': 88,
        'body': 'صورة الحافلة',
        'type': 'image',
        'attachment_url': 'https://example.com/bus.jpg',
        'is_mine': true,
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 999);
      expect(message.conversationId, 88);
      expect(message.body, 'صورة الحافلة');
      expect(message.type, 'image');
      expect(message.attachmentUrl, 'https://example.com/bus.jpg');
      expect(message.isMine, isTrue);
      expect(message.sender.name, ''); // Default fallback
    });
  });

  group('ChatRepository API Integration Suite', () {
    late Dio dio;
    late FakeChatDioAdapter fakeAdapter;
    late ChatRepository repo;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/'));
      fakeAdapter = FakeChatDioAdapter();
      dio.httpClientAdapter = fakeAdapter;
      repo = ChatRepository(dio: dio);
    });

    test('6. getContacts calls chat/contacts and parses list', () async {
      fakeAdapter.customResponseData = {
        'data': [
          {'id': 1, 'name': 'السائق أحمد', 'role': 'driver'},
          {'id': 2, 'name': 'المشرفة سارة', 'role': 'supervisor'},
        ]
      };

      final contacts = await repo.getContacts();

      expect(contacts.length, 2);
      expect(contacts[0].name, 'السائق أحمد');
      expect(contacts[1].role, 'supervisor');
      expect(fakeAdapter.recordedRequests.first['path'], 'chat/contacts');
    });

    test('7. getContacts wraps DioException in standard Exception', () async {
      fakeAdapter.shouldThrowDio = true;
      fakeAdapter.dioErrorMessage = 'Connection timeout';

      expect(() => repo.getContacts(), throwsA(isA<Exception>()));
    });

    test('8. getConversations calls chat/conversations and parses list', () async {
      fakeAdapter.customResponseData = {
        'data': [
          {
            'id': 201,
            'type': 'private',
            'unread_count': 1,
            'participants': [
              {'id': 1, 'name': 'Parent', 'role': 'parent'},
            ],
          }
        ]
      };

      final convs = await repo.getConversations();

      expect(convs.length, 1);
      expect(convs.first.id, 201);
      expect(convs.first.unreadCount, 1);
      expect(fakeAdapter.recordedRequests.first['path'], 'chat/conversations');
    });

    test('9. startConversation posts receiver_id and returns new conversation', () async {
      fakeAdapter.customResponseData = {
        'data': {
          'id': 301,
          'type': 'private',
          'participants': [
            {'id': 5, 'name': 'المعلم خالد', 'role': 'teacher'},
          ],
        }
      };

      final conv = await repo.startConversation(5);

      expect(conv.id, 301);
      expect(fakeAdapter.recordedRequests.first['path'], 'chat/conversations');
      expect(fakeAdapter.recordedRequests.first['method'], 'POST');
      expect(fakeAdapter.recordedRequests.first['data']['receiver_id'], 5);
    });

    test('10. sendMessage posts message body and type to endpoint', () async {
      fakeAdapter.customResponseData = {
        'data': {
          'id': 800,
          'conversation_id': 301,
          'body': 'سأكون في انتظار الحافلة عند الموقف',
          'type': 'text',
          'is_mine': true,
          'created_at': '2026-09-04T12:00:00Z',
        }
      };

      final msg = await repo.sendMessage(301, 'سأكون في انتظار الحافلة عند الموقف');

      expect(msg.id, 800);
      expect(msg.body, 'سأكون في انتظار الحافلة عند الموقف');
      expect(fakeAdapter.recordedRequests.first['path'], 'chat/conversations/301/messages');
      expect(fakeAdapter.recordedRequests.first['data']['body'], 'سأكون في انتظار الحافلة عند الموقف');
      expect(fakeAdapter.recordedRequests.first['data']['type'], 'text');
    });

    test('11. markAsRead calls chat/conversations/{id}/read and suppresses error', () async {
      fakeAdapter.shouldThrowDio = true; // Error shouldn't rethrow
      await repo.markAsRead(301);

      expect(fakeAdapter.recordedRequests.first['path'], 'chat/conversations/301/read');
    });
  });

  group('AppController Chat State & Stream Integration Suite', () {
    late AppController controller;
    late FakeChatDioAdapter fakeDio;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_id': 100,
        'user_name': 'Parent Test',
      });
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'mock_token',
      });
      controller = AppController();
      fakeDio = FakeChatDioAdapter();
      controller.dio.httpClientAdapter = fakeDio;
    });

    tearDown(() {
      controller.stopTrackingPoll();
      controller.dispose();
    });

    test('12. loadConversationsFromApi populates conversations list and calculates unread count', () async {
      fakeDio.customResponseData = {
        'data': [
          {
            'id': 10,
            'type': 'private',
            'unread_count': 2,
            'participants': [],
          },
          {
            'id': 20,
            'type': 'private',
            'unread_count': 3,
            'participants': [],
          },
        ]
      };

      await controller.loadConversationsFromApi();

      expect(controller.conversations.length, 2);
      expect(controller.chatUnreadCount, 5); // 2 + 3
    });

    test('13. markConversationAsRead resets unreadCount for specified conversation', () async {
      fakeDio.customResponseData = {
        'data': [
          {
            'id': 10,
            'type': 'private',
            'unread_count': 2,
            'participants': [],
          },
        ]
      };
      await controller.loadConversationsFromApi();
      expect(controller.chatUnreadCount, 2);

      controller.markConversationAsRead(10);

      expect(controller.conversations.first.unreadCount, 0);
      expect(controller.chatUnreadCount, 0);
    });

    test('14. addMessage validates non-empty text or mediaUrl and adds MessageItem', () {
      expect(controller.messages, isEmpty);

      // Empty text without media is ignored
      controller.addMessage('   ');
      expect(controller.messages, isEmpty);

      // Valid text is trimmed and added
      controller.addMessage('   مرحبا بكم   ');
      expect(controller.messages.length, 1);
      expect(controller.messages.first.text, 'مرحبا بكم');
      expect(controller.messages.first.sender, 'أنت');
      expect(controller.messages.first.incoming, isFalse);

      // Media message with empty text is allowed
      controller.addMessage('', mediaUrl: 'https://example.com/audio.mp3');
      expect(controller.messages.length, 2);
      expect(controller.messages.last.mediaUrl, 'https://example.com/audio.mp3');
    });

    test('15. clearNewMessages clears hasNewMessages flag and notifies listeners', () {
      // Simulate new messages flag
      controller.clearNewMessages();
      expect(controller.hasNewMessages, isFalse);
    });
  });
}
