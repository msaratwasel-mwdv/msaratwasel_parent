import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/utils/labels.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final students = controller.students;
    final notifications = controller.notifications;
    final isArabic = controller.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Navigation Bar
        // Navigation Bar
        AppSliverHeader(
          title: context.t('home'),
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

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Welcome Header
              _WelcomeHeader(isDark: isDark),
              const SizedBox(height: AppSpacing.xl),

              // Summary Stats
              _SummaryStats(
                students: students,
                notifications: notifications,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Children Quick View
              _SectionTitle(title: context.t('myKids'), isDark: isDark),
              const SizedBox(height: AppSpacing.md),
              ...students.map(
                (student) => _ChildQuickCard(
                  student: student,
                  isArabic: isArabic,
                  isDark: isDark,
                  onTap: () =>
                      controller.setNavIndex(1), // Navigate to Children screen
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Recent Notifications
              _SectionTitle(title: context.t('notifications'), isDark: isDark),
              const SizedBox(height: AppSpacing.md),
              _RecentNotifications(
                notifications: notifications.take(3).toList(),
                isArabic: isArabic,
                isDark: isDark,
                onViewAll: () =>
                    controller.setNavIndex(4), // Navigate to Notifications
              ),
              const SizedBox(height: AppSpacing.xl),

              // Quick Actions
              _SectionTitle(
                title: context.t('quickActionsTitle'),
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.md),
              _QuickActions(controller: controller, isDark: isDark),

              const SizedBox(height: AppSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = context.t('greetingMorning');
    } else if (hour < 17) {
      greeting = context.t('greetingAfternoon');
    } else {
      greeting = context.t('greetingEvening');
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400",
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.t('welcomeUser')} ${AppScope.of(context).userName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.t('guardianRole'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
}

class _SummaryStats extends StatelessWidget {
  const _SummaryStats({
    required this.students,
    required this.notifications,
    required this.isDark,
  });

  final List<Student> students;
  final List<AppNotification> notifications;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final onBusCount = students
        .where((s) => s.status == StudentStatus.onBus)
        .length;
    final unreadCount = notifications.where((n) => !n.read).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.family_restroom_rounded,
            value: students.length.toString(),
            label: context.t(
              'myKids',
            ), // Reusing key 'myKids' or specifically 'Kids'
            color: isDark ? AppColors.dark.accent : AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.directions_bus_rounded,
            value: onBusCount.toString(),
            label: context.t(
              'busTracking',
            ), // Or a shorter 'On Bus' key if available, falling back to existing
            color: AppColors.accent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.notifications_active_rounded,
            value: unreadCount.toString(),
            label: context.t('notifications'),
            color: AppColors.error,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label, // Already localized
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChildQuickCard extends StatelessWidget {
  const _ChildQuickCard({
    required this.student,
    required this.isArabic,
    required this.isDark,
    required this.onTap,
  });

  final Student student;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusText = Labels.studentStatus(student.status, arabic: isArabic);
    final statusIcon = _statusIcon(student.status);
    final statusColor = _getStatusColor(student.status, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    student.name[0],
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.t('studentGrade')}: ${student.grade}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(StudentStatus status) {
    switch (status) {
      case StudentStatus.onBus:
        return Icons.directions_bus_filled_outlined;
      case StudentStatus.atSchool:
        return Icons.school_outlined;
      case StudentStatus.atHome:
        return Icons.home_outlined;
      case StudentStatus.notBoarded:
        return Icons.hourglass_top_outlined;
      case StudentStatus.late:
        return Icons.warning_amber_outlined;
    }
  }

  Color _getStatusColor(StudentStatus status, bool isDark) {
    if (isDark && status == StudentStatus.atSchool) {
      return Colors.white;
    }
    switch (status) {
      case StudentStatus.onBus:
        return AppColors.accent;
      case StudentStatus.atSchool:
        return AppColors.primary;
      case StudentStatus.atHome:
        return Colors.green;
      case StudentStatus.notBoarded:
        return Colors.orange;
      case StudentStatus.late:
        return AppColors.error;
    }
  }
}

class _RecentNotifications extends StatelessWidget {
  const _RecentNotifications({
    required this.notifications,
    required this.isArabic,
    required this.isDark,
    required this.onViewAll,
  });

  final List<AppNotification> notifications;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ...notifications.map(
            (notification) => _NotificationItem(
              notification: notification,
              isDark: isDark,
              isArabic: isArabic,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onViewAll,
            child: Text(
              context.t('viewAll'),
              style: TextStyle(
                color: isDark ? AppColors.dark.accent : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.notification,
    required this.isDark,
    required this.isArabic,
  });

  final AppNotification notification;
  final bool isDark;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(notification.time, isArabic);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: notification.read ? Colors.grey : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time, bool isArabic) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return isArabic ? 'منذ $minutes دقيقة' : '$minutes min ago';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return isArabic ? 'منذ $hours ساعة' : '$hours h ago';
    } else {
      final days = diff.inDays;
      return isArabic ? 'منذ $days يوم' : '$days d ago';
    }
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller, required this.isDark});

  final AppController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.directions_bus_rounded,
            label: context.t('track'),
            color: AppColors.accent,
            isDark: isDark,
            onTap: () => controller.setNavIndex(2),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.chat_bubble_rounded,
            label: context.t('chat'), // Was 'رسائل' which matches 'chat' key
            color: isDark ? AppColors.dark.accent : AppColors.primary,
            isDark: isDark,
            onTap: () => controller.setNavIndex(5),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.calendar_month_rounded,
            label: context.t('attendance'), // Was 'حضور'
            color: Colors.orange,
            isDark: isDark,
            onTap: () => controller.setNavIndex(7),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.settings_rounded,
            label: context.t('settings'),
            color: Colors.grey,
            isDark: isDark,
            onTap: () => controller.setNavIndex(9),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
