import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/chat_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('notifications')),
        centerTitle: true,
        actions: [
          // Clear all button for better UX
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
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.1),
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
                            child: const Icon(
                              Icons.notifications,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.body),
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
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
