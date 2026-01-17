import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:intl/intl.dart';

class ChildrenStatusPage extends StatelessWidget {
  const ChildrenStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final students = controller.students;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = controller.locale.languageCode == 'ar';

    return CustomScrollView(
      slivers: [
        AppSliverHeader(
          title: context.t('childrenStatus'),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final student = students[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _ChildStatusCard(
                  student: student,
                  isDark: isDark,
                  isArabic: isArabic,
                  context: context,
                ),
              );
            }, childCount: students.length),
          ),
        ),
      ],
    );
  }
}

class _ChildStatusCard extends StatelessWidget {
  const _ChildStatusCard({
    required this.student,
    required this.isDark,
    required this.isArabic,
    required this.context,
  });

  final Student student;
  final bool isDark;
  final bool isArabic;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16), // Match Standard
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, // Match Standard (reduced from 20)
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Avatar with Ring
                Container(
                  padding: const EdgeInsets.all(2), // Thinner padding
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22, // Slightly adjusted
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      student.name[0],
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontSize: 16, // Consistent size
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'EEEE, d MMM',
                          isArabic ? 'ar' : 'en',
                        ).format(DateTime.now()),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.1),
          ),

          // Additional Info: Wait Time (Simplified)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.t('timeWaited'),
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '5 ${context.t('minutesSuffix')}', // Mock Data
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.1),
          ),

          // Timelines
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimelineStep(
                  label: context.t('atHome'),
                  time: '06:30 AM',
                  isActive: true,
                  isCompleted: true,
                  isDark: isDark,
                  stepIcon: Icons.home_rounded,
                ),
                Expanded(
                  child: _TimelineConnector(isCompleted: true, isDark: isDark),
                ),
                _TimelineStep(
                  label: context.t('onBus'),
                  time: '06:45 AM',
                  isActive: true,
                  isCompleted: true,
                  isDark: isDark,
                  stepIcon: Icons.directions_bus_rounded,
                ),
                Expanded(
                  child: _TimelineConnector(isCompleted: true, isDark: isDark),
                ),
                _TimelineStep(
                  label: context.t('atSchool'),
                  time: '07:15 AM',
                  isActive: true,
                  isCompleted: true,
                  isDark: isDark,
                  stepIcon: Icons.school_rounded,
                ),
                Expanded(
                  child: _TimelineConnector(isCompleted: false, isDark: isDark),
                ),
                _TimelineStep(
                  label: context.t('onBus'),
                  time: '--:--',
                  isActive: false,
                  isCompleted: false,
                  isDark: isDark,
                  stepIcon: Icons.directions_bus_rounded,
                ),
                Expanded(
                  child: _TimelineConnector(isCompleted: false, isDark: isDark),
                ),
                _TimelineStep(
                  label: context.t('atHome'),
                  time: '--:--',
                  isActive: false,
                  isCompleted: false,
                  isDark: isDark,
                  stepIcon: Icons.home_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.isCompleted, required this.isDark});

  final bool isCompleted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2, // Very thin, faint line
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white10
            : Colors.grey.withValues(alpha: 0.1), // Never Green
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.time,
    required this.isActive,
    required this.isCompleted,
    required this.isDark,
    required this.stepIcon,
  });

  final String label;
  final String time;
  final bool isActive;
  final bool isCompleted;
  final bool isDark;
  final IconData stepIcon;

  @override
  Widget build(BuildContext context) {
    // Determine colors based on state
    final Color circleColor;
    final Color iconColor;
    final Color borderColor;

    if (isCompleted) {
      circleColor = Colors.green;
      iconColor = Colors.white;
      borderColor = Colors.green;
    } else if (isActive) {
      // Active: Filled with primary
      circleColor = AppColors.primary;
      iconColor = Colors.white;
      borderColor = AppColors.primary;
    } else {
      // Pending
      circleColor = Colors.transparent;
      iconColor = isDark
          ? Colors.white30
          : const Color(0xFFCBD5E1); // Slate-300
      borderColor = isDark
          ? Colors.white12
          : const Color(0xFFE2E8F0); // Slate-200
    }

    return Column(
      children: [
        Container(
          width: 44, // Slightly larger
          height: 44,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isActive || isCompleted
                ? [
                    BoxShadow(
                      color: circleColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isCompleted ? Icons.check_rounded : stepIcon,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isCompleted
                ? FontWeight.bold
                : FontWeight.w500,
            color: isDark
                ? (isActive || isCompleted ? Colors.white : Colors.white54)
                : (isActive || isCompleted
                      ? AppColors.textPrimary
                      : AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Colors.white38
                : AppColors.textSecondary.withValues(alpha: 0.7),
            fontFamily: 'Roboto', // Ensure numbers look good
          ),
        ),
      ],
    );
  }
}
