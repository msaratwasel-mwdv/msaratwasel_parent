import 'package:dio/dio.dart';
import 'package:msaratwasel_user/src/features/communication/domain/entities/message_thread.dart';
import './communication_repository.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final Dio dio;

  CommunicationRepositoryImpl({required this.dio});

  @override
  Future<MessageThread> fetchThread(String threadId) async {
    final response = await dio.get('guardian/communication/threads/$threadId');
    final data = response.data['data'];
    final List<dynamic> messagesJson = data['messages'] ?? [];
    
    return MessageThread(
      id: data['id'].toString(),
      participants: (data['participants'] as List?)?.map((p) => p['name'].toString()).toList() ?? [],
      messages: messagesJson.map((json) {
        return MessageItem(
          id: json['id'].toString(),
          sender: json['sender_name'] ?? '',
          text: json['body'] ?? '',
          time: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
          incoming: json['is_incoming'] == true,
        );
      }).toList(),
    );
  }

  @override
  Future<void> sendMessage({required String threadId, required String text}) async {
    await dio.post('guardian/communication/threads/$threadId/messages', data: {
      'body': text,
    });
  }
}
