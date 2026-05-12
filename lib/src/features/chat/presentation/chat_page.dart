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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:msaratwasel_user/src/shared/widgets/user_avatar.dart';
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
      ActiveConversationTracker.setActiveConversation(widget.conversationId.toString());
      final app = AppScope.of(context);
      _repo = ChatRepository(dio: app.dio);
      _loadMessages();
      
      // Real-time: Subscribe to the conversation channel
      app.subscribeToChat(widget.conversationId.toString());
      
      // Real-time: Listen for incoming messages from AppController
      _messageSubscription = app.messageStream.listen((data) {
        _handleWebSocketMessage(data);
      });

      // Mark as read on open
      _repo.markAsRead(widget.conversationId);
      // Schedule polling for new messages (as fallback)
      _schedulePoll();
      _isInit = true;
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageData = data['message'];
    if (messageData == null) return;

    final conversationId = messageData['conversation_id'];
    if (conversationId != widget.conversationId) return;

    final newMessage = ChatMessage.fromJson(messageData);
    
    // Avoid duplicates
    if (!_messages.any((m) => m.id == newMessage.id)) {
      developer.log('🚀 ChatPage: Received real-time message', name: 'CHAT');
      setState(() {
        _messages.insert(0, newMessage);
      });
      // Mark as read
      _repo.markAsRead(widget.conversationId);
    }
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(const Duration(seconds: 10), _pollNewMessages); // Increased interval since we have WS
  }

  @override
  void dispose() {
    ActiveConversationTracker.clearActiveConversation();
    final app = AppScope.of(context);
    app.unsubscribeFromChat(widget.conversationId.toString());
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
        // Also mark as read on the server if we got new messages while polling
        _repo.markAsRead(widget.conversationId);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${context.t('failedToSendMessage')}: $e')));
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
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppColors.primary,
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
                                    _DateSeparator(
                                      date: msg.createdAt,
                                    ),
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
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom:
                        MediaQuery.of(context).padding.bottom + AppSpacing.md,
                    top: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: context.t('typeMessage'),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brandGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(90),
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
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
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
    final isMine = message.isMine || (currentUserId != null && message.sender.id == currentUserId);
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleColor = isMine
        ? const Color(0xFF1E508E)
        : (isDark
              ? const Color(0xFF334155)
              : Colors.white.withValues(alpha: 0.85));
    final textColor = isMine
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? 18 : 4),
      topRight: Radius.circular(isMine ? 4 : 18),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: UserAvatar(
                  name: message.sender.name,
                  avatarUrl: message.sender.avatarUrl,
                  fallbackIcon: message.sender.role == 'driver'
                      ? Icons.directions_bus_rounded
                      : Icons.support_agent_rounded,
                  radius: 14,
                  fontSize: 10,
                ),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: radius,
                  border: isMine
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine)
                      Text(
                        message.sender.name,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    if (!isMine) const SizedBox(height: AppSpacing.xs),
                    if (message.body.isNotEmpty)
                      Text(
                        message.body,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: textColor),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date_utils.formatTime(
                            message.createdAt,
                            locale: Localizations.localeOf(context).languageCode,
                          ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isMine
                                    ? Colors.white70
                                    : AppColors.textSecondary,
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
          ],
        ),
      ),
    );
  }
}
