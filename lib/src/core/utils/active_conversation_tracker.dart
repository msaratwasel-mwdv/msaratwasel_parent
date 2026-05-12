class ActiveConversationTracker {
  static String? _activeConversationId;

  static String? get activeConversationId => _activeConversationId;

  static void setActiveConversation(String id) {
    _activeConversationId = id;
  }

  static void clearActiveConversation() {
    _activeConversationId = null;
  }
}
