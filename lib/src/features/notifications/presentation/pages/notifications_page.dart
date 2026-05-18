import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/chat_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Handle pending notification after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotification();
    });
  }

  void _checkPendingNotification() {
    final controller = AppScope.of(context);
    final pendingId = controller.pendingNotificationId;
    if (pendingId != null) {
      // Find the notification in the list
      final notification = controller.notifications.cast<AppNotification?>().firstWhere(
            (n) => n?.id == pendingId,
            orElse: () => null,
          );

      if (notification != null) {
        // Mark it as read
        controller.markNotificationsRead([notification.id]);
        // Clear the pending ID so it doesn't trigger again
        controller.clearPendingNotificationId();
        
        debugPrint('🔔 Handled pending notification: $pendingId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('notifications')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.t('confirm')),
                  content: const Text('هل تريد مسح جميع الإشعارات؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.t('cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.t('delete')),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await controller.clearNotifications();
              }
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final notifications = controller.notifications;
          final pendingId = controller.pendingNotificationId;

          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadNotificationsFromApi();
            },
            color: isDark
                ? Theme.of(context).colorScheme.secondary
                : AppColors.primary,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: notifications.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                context.t('noNotifications'),
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isPending = notification.id == pendingId;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isPending
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isPending 
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : AppColors.border.withValues(alpha: 0.1),
                              width: isPending ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              controller.markNotificationsRead([notification.id]);

                              if (notification.type ==
                                      NotificationType.supervisorMessage ||
                                  notification.type == NotificationType.chat) {
                                final rawId =
                                    notification.data['conversation_id'] ??
                                    notification.data['id'];

                                final convId = int.tryParse(rawId?.toString() ?? '');

                                if (convId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        conversationId: convId,
                                        contactName:
                                            notification.data['sender_name']
                                                ?.toString() ??
                                            (notification.type ==
                                                    NotificationType.supervisorMessage
                                                ? context.t('supervisor')
                                                : context.t('chat')),
                                        contactRole:
                                            notification.data['sender_role']
                                                ?.toString() ??
                                            (notification.type ==
                                                    NotificationType.supervisorMessage
                                                ? 'supervisor'
                                                : ''),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: isPending ? AppColors.primary : AppColors.primary.withValues(alpha: 0.7),
                              ),
                            ),
                            title: Text(
                              notification.getDisplayTitle(AppScope.of(context).locale.languageCode == 'en'),
                              style: TextStyle(
                                fontWeight: isPending ? FontWeight.w900 : FontWeight.bold,
                                color: isPending ? AppColors.primary : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.getDisplayBody(AppScope.of(context).locale.languageCode == 'en')),
                                const SizedBox(height: 4),
                                Text(
                                  '${notification.time.hour == 0 ? 12 : (notification.time.hour > 12 ? notification.time.hour - 12 : notification.time.hour)}:${notification.time.minute.toString().padLeft(2, '0')} ${notification.time.hour >= 12 ? context.t('pm') : context.t('am')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
