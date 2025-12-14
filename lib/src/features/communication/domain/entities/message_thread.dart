class MessageThread {
  MessageThread({
    required this.id,
    required this.participants,
    required this.messages,
  });

  final String id;
  final List<String> participants;
  final List<MessageItem> messages;
}

class MessageItem {
  MessageItem({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.incoming,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime time;
  final bool incoming;
}
