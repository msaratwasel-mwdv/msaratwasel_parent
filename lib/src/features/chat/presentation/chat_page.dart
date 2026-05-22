import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/features/chat/data/models/chat_models.dart';
import 'package:msaratwasel_user/src/features/chat/data/repositories/chat_repository.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/utils/date_utils.dart'
    as date_utils;
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/core/utils/active_conversation_tracker.dart';
import 'package:msaratwasel_user/src/shared/widgets/user_avatar.dart';
import 'package:msaratwasel_user/src/shared/widgets/directional_icon.dart';

/// Real-time chat page connected to the Laravel Chat API.
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactRole,
    this.avatarUrl,
  });

  final int conversationId;
  final String contactName;
  final String contactRole;
  final String? avatarUrl;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatRepository _repo;
  late final AppController _appController;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _pollTimer;
  StreamSubscription? _messageSubscription;
  bool _isInit = false;
  bool _isPolling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      ActiveConversationTracker.setActiveConversation(
        widget.conversationId.toString(),
      );
      final app = AppScope.of(context);
      _appController = app;
      _repo = ChatRepository(dio: app.dio);
      _loadMessages();

      // Real-time: Subscribe to the conversation channel
      app.subscribeToChat(widget.conversationId.toString());

      // Real-time: Listen for incoming messages from AppController
      _messageSubscription = app.messageStream.listen((data) {
        _handleWebSocketMessage(data);
      });

      // Mark as read on open (API + central state)
      _repo.markAsRead(widget.conversationId);
      app.markConversationAsRead(widget.conversationId);
      // Schedule polling for new messages (as fallback)
      _schedulePoll();
      _isInit = true;
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageData = data['message'];
    if (messageData == null) return;

    final conversationId = messageData['conversation_id'];
    if (conversationId?.toString() != widget.conversationId.toString()) return;

    // Parse IDs safely
    final idRaw = messageData['id'];
    final msgId = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch;

    // Avoid duplicates
    if (!_messages.any((m) => m.id == msgId)) {
      developer.log('🚀 ChatPage: Received real-time message', name: 'CHAT');
      
      final senderIdRaw = messageData['from_user_id'];
      final senderId = senderIdRaw is int ? senderIdRaw : int.tryParse(senderIdRaw?.toString() ?? '') ?? 0;
      final isMine = senderId.toString() == _appController.userId?.toString();

      final newMessage = ChatMessage(
        id: msgId,
        conversationId: widget.conversationId,
        sender: ChatMessageSender(
          id: senderId,
          name: messageData['sender_name']?.toString() ?? (isMine ? 'أنت' : 'المدرسة'),
          role: 'مدرسة',
        ),
        body: messageData['content']?.toString() ?? messageData['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(messageData['created_at']?.toString() ?? '') ?? DateTime.now(),
        isMine: isMine,
        attachmentUrl: messageData['media_url']?.toString() ?? messageData['attachment_url']?.toString(),
      );

      setState(() {
        _messages.insert(0, newMessage);
      });
      // Mark as read (API + central state)
      _repo.markAsRead(widget.conversationId);
      _appController.markConversationAsRead(widget.conversationId);
    }
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(
      const Duration(seconds: 10),
      _pollNewMessages,
    ); // Increased interval since we have WS
  }

  @override
  void dispose() {
    ActiveConversationTracker.clearActiveConversation();
    _appController.unsubscribeFromChat(widget.conversationId.toString());
    _messageSubscription?.cancel();
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _repo.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log(
        '❌ ChatPage: load messages failed',
        name: 'CHAT',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Silently fetch new messages without showing loading.
  Future<void> _pollNewMessages() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final messages = await _repo.getMessages(widget.conversationId);
      if (!mounted) return;
      if (messages.length != _messages.length) {
        setState(() => _messages = messages);
        // Also mark as read on the server + central state
        _repo.markAsRead(widget.conversationId);
        AppScope.of(context).markConversationAsRead(widget.conversationId);
      }
    } catch (_) {
      // Silently ignore poll errors
    } finally {
      if (mounted) {
        _isPolling = false;
        _schedulePoll();
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() => _isSending = true);

    try {
      final sent = await _repo.sendMessage(widget.conversationId, text);
      if (!mounted) return;
      setState(() {
        // API returns newest first, insert at beginning
        _messages.insert(0, sent);
        _isSending = false;
      });
    } catch (e) {
      developer.log('❌ ChatPage: send message failed', name: 'CHAT', error: e);
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.t('failedToSendMessage')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isArabic = app.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDriver = widget.contactRole == 'driver';
    final roleLabel = isDriver ? context.t('driver') : context.t('supervisor');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              name: widget.contactName,
              avatarUrl: widget.avatarUrl,
              fallbackIcon: widget.contactRole == 'driver'
                  ? Icons.directions_bus_rounded
                  : Icons.support_agent_rounded,
              token: app.token,
              radius: 14,
              fontSize: 10,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: DirectionalIcon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.primary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(context)
          : Column(
              children: [
                // ── Messages List ──
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmpty(context)
                      : RefreshIndicator(
                          onRefresh: _loadMessages,
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.lg,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final previous = index + 1 < _messages.length
                                  ? _messages[index + 1]
                                  : null;
                              final showDate =
                                  previous == null ||
                                  msg.createdAt.day != previous.createdAt.day ||
                                  msg.createdAt.month !=
                                      previous.createdAt.month ||
                                  msg.createdAt.year != previous.createdAt.year;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showDate)
                                    _DateSeparator(date: msg.createdAt),
                                  _MessageBubble(
                                    message: msg,
                                    isArabic: isArabic,
                                    isDark: isDark,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),

                // ── Input Bar ──
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom:
                        MediaQuery.of(context).padding.bottom + 12,
                    top: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: context.t('typeMessage'),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brandGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : IconButton(
                                  onPressed: _sendMessage,
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.t('failedToLoadMessages')),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.t('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.t('noMessages'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.t('startChattingNow'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Date Separator ─────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = context.t('today');
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = context.t('yesterday');
    } else {
      label = date_utils.formatDate(date, locale: locale);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isArabic,
    required this.isDark,
  });

  final ChatMessage message;
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppScope.of(context).userId;
    final isMine =
        message.isMine ||
        (currentUserId != null && message.sender.id == currentUserId);
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleDecoration = isMine
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E508E), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          );

    final textColor = isMine
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);

    final textDir = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: alignment,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: UserAvatar(
                    name: message.sender.name,
                    avatarUrl: message.sender.avatarUrl,
                    fallbackIcon: message.sender.role == 'driver'
                        ? Icons.directions_bus_rounded
                        : Icons.support_agent_rounded,
                    token: AppScope.of(context).token,
                    radius: 16,
                    fontSize: 11,
                  ),
                ),
              Flexible(
                child: Directionality(
                  textDirection: textDir,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: bubbleDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isMine) ...[
                          Text(
                            message.sender.name,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF64B5F6)
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (message.body.isNotEmpty)
                          Text(
                            message.body,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                                  color: textColor,
                                  height: 1.3,
                                ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              date_utils.formatTime(
                                message.createdAt,
                                locale: Localizations.localeOf(
                                  context,
                                ).languageCode,
                              ),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: isMine
                                        ? Colors.white70
                                        : (isDark
                                            ? Colors.white60
                                            : AppColors.textSecondary),
                                    fontSize: 10,
                                  ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
