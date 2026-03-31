import '../../domain/entities/message_thread.dart';

abstract class CommunicationRepository {
  /// Send message to bus attendant or school.
  Future<void> sendMessage({required String threadId, required String text});

  /// Fetch conversation thread.
  Future<MessageThread> fetchThread(String threadId);
}
