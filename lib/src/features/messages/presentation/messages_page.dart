import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/utils/date_utils.dart'
    as date_utils;

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isArabic = app.locale.languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final messages = app.messages.reversed.toList();
        final hasMessages = messages.isNotEmpty;
        final isSupervisorTyping =
            messages.isNotEmpty && messages.first.incoming;
        final name = isArabic ? 'عائشة' : 'Aisha';
        // final role = isArabic ? 'مشرفة الحافلة' : 'Bus Supervisor';

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              CupertinoSliverNavigationBar(
                largeTitle: Text(name),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                    width: 0.0,
                  ),
                ),
                leading: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(Icons.menu_rounded, color: AppColors.primary),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.call_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.videocam_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: hasMessages
                      ? ListView.builder(
                          // controller: _scrollController, // let NestedScrollView handle it?
                          // Actually, for reverse list in NestedScrollView, it's tricky.
                          // Standard NestedScrollView body expects top-to-bottom.
                          // If I use reverse: true, the scroll might not link to header correctly.
                          // Let's try keeping the controller separate first,
                          // BUT NestedScrollView acts on the OUTER scrollable.
                          // If ListView has its own controller, OUTER won't scroll.
                          // So Header won't collapse.
                          // To make Header collapse, the scrolling must occur on the NestedScrollView's viewport.
                          // This works if we use `CustomScrollView` with `SliverList` inside `body`? No.
                          // Let's try omitting controller so it uses Primary (injected by NestedScrollView).
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.lg,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final previous = index + 1 < messages.length
                                ? messages[index + 1]
                                : null;
                            final showDateSeparator =
                                previous == null ||
                                msg.time.day != previous.time.day ||
                                msg.time.month != previous.time.month ||
                                msg.time.year != previous.time.year;

                            final widgets = <Widget>[];

                            if (showDateSeparator) {
                              widgets.add(
                                _DateSeparator(
                                  date: msg.time,
                                  isArabic: isArabic,
                                ),
                              );
                            }

                            widgets.add(
                              _MessageBubble(
                                message: msg,
                                isArabic: isArabic,
                                isParent: !msg.incoming,
                              ),
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widgets,
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                isArabic
                                    ? 'لا توجد رسائل بعد'
                                    : 'No messages yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                isArabic
                                    ? 'ابدأ المراسلة مع المشرفة'
                                    : 'Start chatting with the supervisor',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (isSupervisorTyping) const _TypingIndicator(),
                if (isSupervisorTyping) const SizedBox(height: AppSpacing.sm),
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
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.attach_file_rounded),
                        color: AppColors.textSecondary,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.photo_camera_outlined),
                        color: AppColors.textSecondary,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          style: textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: isArabic
                                ? 'اكتب رسالتك…'
                                : 'Type your message…',
                          ),
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
                          child: IconButton(
                            onPressed: () {
                              app.addMessage(_controller.text);
                              _controller.clear();
                              FocusScope.of(context).unfocus();
                            },
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
          ),
        );
      },
    );
  }
}

// _ChatHeader class removed as it is replaced by CupertinoSliverNavigationBar

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date, required this.isArabic});

  final DateTime date;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = isArabic ? 'اليوم' : 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = isArabic ? 'أمس' : 'Yesterday';
    } else {
      label = date_utils.formatDate(date, locale: isArabic ? 'ar' : 'en');
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isArabic,
    required this.isParent,
  });

  final MessageItem message;
  final bool isArabic;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    final alignment = isParent ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isParent
        ? const Color(0xFF1E508E)
        : (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155)
              : Colors.white.withValues(alpha: 0.85));
    final textColor = isParent
        ? Colors.white
        : (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.textPrimary);
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isParent ? 18 : 4),
      topRight: Radius.circular(isParent ? 4 : 18),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );

    // Simple status placeholder for parent messages.
    final statusIcon = isParent ? Icons.done_all_rounded : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isParent)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withAlpha(71),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: radius,
                  border: isParent
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
                    if (!isParent)
                      Text(
                        message.sender,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    if (!isParent) const SizedBox(height: AppSpacing.xs),
                    Text(
                      message.text,
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
                            message.time,
                            locale: isArabic ? 'ar' : 'en',
                          ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isParent
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                              ),
                        ),
                        if (statusIcon != null) ...[
                          const SizedBox(width: 4),
                          Icon(statusIcon, size: 14, color: Colors.white70),
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

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _TypingDot(delay: 0),
              SizedBox(width: 4),
              _TypingDot(delay: 150),
              SizedBox(width: 4),
              _TypingDot(delay: 300),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});

  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.delay / 600, 1, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
    );
  }
}
