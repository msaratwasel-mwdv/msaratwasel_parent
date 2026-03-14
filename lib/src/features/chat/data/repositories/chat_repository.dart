import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_user/src/core/config/app_config.dart';
import 'package:msaratwasel_user/src/features/chat/data/models/chat_models.dart';

/// Repository that talks to the Laravel Chat API endpoints.
class ChatRepository {
  ChatRepository({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.defaultTimeout,
    receiveTimeout: AppConfig.defaultTimeout,
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  ));

  final Dio _dio;

  // ─── Auth helper ──────────────────────────────────────────────────────
  Future<Options> _authOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  1. Contacts — GET /api/chat/contacts
  // ═══════════════════════════════════════════════════════════════════════
  Future<List<ChatContact>> getContacts() async {
    try {
      final response = await _dio.get('chat/contacts', options: await _authOptions());
      return (response.data['data'] as List)
          .map((json) => ChatContact.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load contacts: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  2. Conversations — GET /api/chat/conversations
  // ═══════════════════════════════════════════════════════════════════════
  Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await _dio.get('chat/conversations', options: await _authOptions());
      return (response.data['data'] as List)
          .map((json) => ChatConversation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load conversations: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  3. Start / Get conversation — POST /api/chat/conversations
  // ═══════════════════════════════════════════════════════════════════════
  Future<ChatConversation> startConversation(int receiverId) async {
    try {
      final response = await _dio.post(
        'chat/conversations',
        data: {'receiver_id': receiverId},
        options: await _authOptions(),
      );
      developer.log('💬 ChatRepo: conversation started with user $receiverId', name: 'CHAT');
      return ChatConversation.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } catch (e, st) {
      developer.log('❌ ChatRepo.startConversation failed', name: 'CHAT', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  4. Send message — POST /api/chat/conversations/{id}/messages
  // ═══════════════════════════════════════════════════════════════════════
  Future<ChatMessage> sendMessage(int conversationId, String body, {String type = 'text'}) async {
    try {
      final response = await _dio.post(
        'chat/conversations/$conversationId/messages',
        data: {'body': body, 'type': type},
        options: await _authOptions(),
      );
      developer.log('💬 ChatRepo: message sent to conv $conversationId', name: 'CHAT');
      return ChatMessage.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } catch (e, st) {
      developer.log('❌ ChatRepo.sendMessage failed', name: 'CHAT', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  5. Get messages — GET /api/chat/conversations/{id}/messages
  // ═══════════════════════════════════════════════════════════════════════
  Future<List<ChatMessage>> getMessages(int conversationId) async {
    try {
      final response = await _dio.get(
        'chat/conversations/$conversationId/messages',
        options: await _authOptions(),
      );
      final data = response.data['data'] as List<dynamic>? ?? [];
      developer.log('💬 ChatRepo: got ${data.length} messages for conv $conversationId', name: 'CHAT');
      return data
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      developer.log('❌ ChatRepo.getMessages failed', name: 'CHAT', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  6. Mark as read — POST /api/chat/conversations/{id}/read
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> markAsRead(int conversationId) async {
    try {
      await _dio.post(
        'chat/conversations/$conversationId/read',
        options: await _authOptions(),
      );
      developer.log('💬 ChatRepo: conv $conversationId marked as read', name: 'CHAT');
    } catch (e, st) {
      developer.log('❌ ChatRepo.markAsRead failed', name: 'CHAT', error: e, stackTrace: st);
      // Non-critical — don't rethrow
    }
  }
}
