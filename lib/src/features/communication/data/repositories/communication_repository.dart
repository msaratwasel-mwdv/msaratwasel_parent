import '../../domain/entities/message_thread.dart';

abstract class CommunicationRepository {
  /// TODO: send message to bus attendant or school.
  Future<void> sendMessage({required String threadId, required String text});

  /// TODO: fetch conversation thread.
  Future<MessageThread> fetchThread(String threadId);
}
