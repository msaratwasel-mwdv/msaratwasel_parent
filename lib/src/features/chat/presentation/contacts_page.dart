import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/features/chat/data/models/chat_models.dart';
import 'package:msaratwasel_user/src/features/chat/data/repositories/chat_repository.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/chat_page.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/widgets/user_avatar.dart';
/// Displays contacts (drivers & supervisors) and existing conversations.
/// Tapping a contact opens/creates a conversation → navigates to [ChatPage].
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  ChatRepository? _repo;

  List<ChatContact> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo == null) {
      _repo = ChatRepository(dio: AppScope.of(context).dio);
    }
    if (_isLoading &&
        _contacts.isEmpty &&
        _error == null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final appController = AppScope.of(context);
      final results = await Future.wait<dynamic>([
        _repo!.getContacts(),
        appController.loadConversationsFromApi(),
      ]);

      if (mounted) {
        setState(() {
          _contacts = (results[0] as List<ChatContact>)
              .where((c) => c.role != 'field_supervisor')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.t('failedToLoad'))));
        });
      }
    }
  }

  Future<void> _openConversation(ChatContact contact) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final conversation = await _repo!.startConversation(contact.id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversationId: conversation.id,
            contactName: contact.name,
            contactRole: contact.role,
            avatarUrl: contact.avatarUrl,
          ),
        ),
      ).then((_) => _loadData()); // Refresh on return
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${context.t('failedToOpenChat')}: $e')));
    }
  }

  Future<void> _openExistingConversation(ChatConversation conv) async {
    final controller = AppScope.of(context);
    final userId = controller.userId;
    final other = conv.otherParticipant(userId ?? 0);

    // Optimistic UI update BEFORE navigation
    controller.markConversationAsRead(conv.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ChatPage(
            conversationId: conv.id,
            contactName: other?.name ?? '',
            contactRole: other?.role ?? '',
            avatarUrl: other?.avatarUrl,
          );
        },
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final conversations = controller.conversations
            .where((c) => !c.participants.any((p) => p.role == 'field_supervisor'))
            .toList();

        return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  AppSliverHeader(
                    title: context.t('chat'),
                    leading: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Contacts Section ──
                        if (_contacts.isNotEmpty) ...[
                          _SectionHeader(
                            title: context.t('contacts'),
                            icon: Icons.people_rounded,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ..._contacts.map(
                            (c) => _ContactTile(
                              contact: c,
                              isDark: isDark,
                              onTap: () => _openConversation(c),
                            ),
                          ),
                        ],
                        // ── Conversations Section ──
                        if (conversations.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _SectionHeader(
                            title: context.t('recentChats'),
                            icon: Icons.chat_rounded,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...conversations.map(
                            (conv) => _ConversationTile(
                              conversation: conv,
                              isDark: isDark,
                              onTap: () => _openExistingConversation(conv),
                            ),
                          ),
                        ],
                        if (_contacts.isEmpty && conversations.isEmpty)
                          _buildEmpty(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.t('failedToLoad'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.t('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl * 2),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.t('noMessages'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
//  Reusable Widgets
// ───────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : AppColors.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.isDark,
    required this.onTap,
  });

  final ChatContact contact;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDriver = contact.role == 'driver';
    final roleLabel = isDriver ? context.t('driver') : context.t('supervisor');
    final avatarIcon = isDriver
        ? Icons.directions_bus_rounded
        : Icons.support_agent_rounded;
    final avatarColor = isDriver
        ? (isDark ? Colors.blue[300]! : const Color(0xFF2563EB))
        : (isDark ? Colors.purple[300]! : const Color(0xFF7C3AED));

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: UserAvatar(
          name: contact.name,
          avatarUrl: contact.avatarUrl,
          fallbackIcon: avatarIcon,
          token: AppScope.of(context).token,
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              roleLabel,
              style: TextStyle(
                fontSize: 12,
                color: avatarColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (contact.chatDescription != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  contact.chatDescription!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chat_rounded,
          color: isDark ? Colors.white54 : AppColors.primary.withValues(alpha: 0.5),
          size: 20,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isDark,
    required this.onTap,
  });

  final ChatConversation conversation;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final userId = AppScope.of(context).userId;
    final other = conversation.otherParticipant(userId ?? 0);
    final name = other?.name ?? context.t('chat');
    final isDriver = other?.role == 'driver';
    final avatarIcon = isDriver
        ? Icons.directions_bus_rounded
        : Icons.support_agent_rounded;

    final lastMsg = conversation.lastMessage;
    final subtitle =
        lastMsg?.body ?? context.t('noMessages');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: UserAvatar(
          name: name,
          avatarUrl: other?.avatarUrl,
          fallbackIcon: avatarIcon,
          token: AppScope.of(context).token,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
        trailing: conversation.unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
      ),
    );
  }
}
