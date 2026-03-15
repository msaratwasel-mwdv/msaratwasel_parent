import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/chat/data/models/chat_models.dart';
import 'package:msaratwasel_user/src/features/chat/data/repositories/chat_repository.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/chat_page.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';

/// Displays contacts (drivers & supervisors) and existing conversations.
/// Tapping a contact opens/creates a conversation → navigates to [ChatPage].
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _repo = ChatRepository();

  List<ChatContact> _contacts = [];
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _repo.getContacts(),
        _repo.getConversations(),
      ]);

      if (mounted) {
        setState(() {
          _contacts = results[0] as List<ChatContact>;
          _conversations = results[1] as List<ChatConversation>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تحميل البيانات')),
          );
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

      final conversation = await _repo.startConversation(contact.id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversationId: conversation.id,
            contactName: contact.name,
            contactRole: contact.role,
          ),
        ),
      ).then((_) => _loadData()); // Refresh on return
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل فتح المحادثة: $e')),
      );
    }
  }

  Future<void> _openExistingConversation(ChatConversation conv) async {
    final other = conv.participants.isNotEmpty ? conv.participants.first : null;
    
    // Optimistic UI update BEFORE navigation
    setState(() {
      conv.unreadCount = 0;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ChatPage(
            conversationId: conv.id,
            contactName: other?.name ?? '',
            contactRole: other?.role ?? '',
          );
        },
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isArabic = app.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'المحادثات' : 'Messages',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
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
              ? _buildError(isArabic)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // ── Contacts Section ──
                      if (_contacts.isNotEmpty) ...[
                        _SectionHeader(
                          title: isArabic ? 'جهات الاتصال' : 'Contacts',
                          icon: Icons.people_rounded,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._contacts.map((c) => _ContactTile(
                              contact: c,
                              isDark: isDark,
                              isArabic: isArabic,
                              onTap: () => _openConversation(c),
                            )),
                      ],
                      // ── Conversations Section ──
                      if (_conversations.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionHeader(
                          title: isArabic ? 'المحادثات السابقة' : 'Recent Chats',
                          icon: Icons.chat_rounded,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._conversations.map((conv) => _ConversationTile(
                              conversation: conv,
                              isDark: isDark,
                              isArabic: isArabic,
                              onTap: () => _openExistingConversation(conv),
                            )),
                      ],
                      // ── Empty State ──
                      if (_contacts.isEmpty && _conversations.isEmpty)
                        _buildEmpty(isArabic),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              isArabic ? 'فشل تحميل البيانات' : 'Failed to load data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isArabic) {
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
              isArabic ? 'لا توجد محادثات بعد' : 'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
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
    required this.isArabic,
    required this.onTap,
  });

  final ChatContact contact;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDriver = contact.role == 'driver';
    final roleLabel = isArabic
        ? (isDriver ? 'سائق' : 'مشرفة')
        : (isDriver ? 'Driver' : 'Supervisor');
    final avatarIcon = isDriver ? Icons.directions_bus_rounded : Icons.support_agent_rounded;
    final avatarColor = isDriver
        ? const Color(0xFF2563EB)
        : const Color(0xFF7C3AED);

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
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: avatarColor.withValues(alpha: 0.15),
          child: Icon(avatarIcon, color: avatarColor, size: 22),
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
          color: AppColors.primary.withValues(alpha: 0.5),
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
    required this.isArabic,
    required this.onTap,
  });

  final ChatConversation conversation;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final other = conversation.participants.isNotEmpty
        ? conversation.participants.first
        : null;
    final name = other?.name ?? (isArabic ? 'محادثة' : 'Chat');
    final isDriver = other?.role == 'driver';
    final avatarIcon = isDriver ? Icons.directions_bus_rounded : Icons.support_agent_rounded;
    final avatarColor = isDriver ? const Color(0xFF2563EB) : const Color(0xFF7C3AED);

    final lastMsg = conversation.lastMessage;
    final subtitle = lastMsg?.body ?? (isArabic ? 'لا توجد رسائل' : 'No messages yet');

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
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: avatarColor.withValues(alpha: 0.15),
          child: Icon(avatarIcon, color: avatarColor, size: 22),
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
