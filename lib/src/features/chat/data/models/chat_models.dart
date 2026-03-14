/// Chat data models — mapped from Laravel Chat API responses.

class ChatContact {
  const ChatContact({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
    this.chatDescription,
  });

  final int id;
  final String name;
  final String role;
  final String? phone;
  final String? chatDescription;

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String?,
      chatDescription: json['chat_description'] as String?,
    );
  }
}

class ChatConversation {
  ChatConversation({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
  });

  final int id;
  final String type;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  int unreadCount;
  final DateTime? updatedAt;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final participantsList = (json['participants'] as List<dynamic>?)
            ?.map((p) => ChatParticipant.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    ChatMessage? lastMsg;
    if (json['last_message'] != null) {
      lastMsg = ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>);
    }

    return ChatConversation(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'private',
      participants: participantsList,
      lastMessage: lastMsg,
      unreadCount: json['unread_count'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Returns the "other" participant (not the current user).
  ChatParticipant? otherParticipant(int myUserId) {
    try {
      return participants.firstWhere((p) => p.id != myUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }
}

class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.name,
    required this.role,
  });

  final int id;
  final String name;
  final String role;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.body,
    this.type = 'text',
    this.attachmentUrl,
    this.isMine = false,
    required this.createdAt,
  });

  final int id;
  final int conversationId;
  final ChatMessageSender sender;
  final String body;
  final String type;
  final String? attachmentUrl;
  final bool isMine;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int? ?? 0,
      sender: ChatMessageSender.fromJson(
        json['sender'] as Map<String, dynamic>? ?? {},
      ),
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      attachmentUrl: json['attachment_url'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ChatMessageSender {
  const ChatMessageSender({
    required this.id,
    required this.name,
    required this.role,
  });

  final int id;
  final String name;
  final String role;

  factory ChatMessageSender.fromJson(Map<String, dynamic> json) {
    return ChatMessageSender(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}
