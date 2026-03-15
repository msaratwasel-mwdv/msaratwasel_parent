import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/tracking_page.dart';
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
                  studentIndex: index,
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
    required this.studentIndex,
    required this.isDark,
    required this.isArabic,
    required this.context,
  });

  final Student student;
  final int studentIndex;
  final bool isDark;
  final bool isArabic;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
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
                const SizedBox(width: AppSpacing.md),
                if (student.status == StudentStatus.onBus || 
                    student.status == StudentStatus.onBusToSchool || 
                    student.status == StudentStatus.onBusToHome)
                  IconButton(
                    onPressed: () {
                      controller.selectStudent(studentIndex);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrackingPage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.map_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: isArabic ? 'تتبع الحافلة' : 'Track Bus',
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

          // Timelines - Full 5-step daily cycle
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.lg,
            ),
            child: Builder(
              builder: (context) {
                final status = student.status;

                // Direct 5-state mapping from enum
                int currentStep;
                switch (status) {
                  case StudentStatus.waitingAtHome:
                  case StudentStatus.notBoarded:
                    currentStep = 1;
                  case StudentStatus.onBusToSchool:
                    currentStep = 2;
                  case StudentStatus.atSchool:
                    currentStep = 3;
                  case StudentStatus.onBusToHome:
                    currentStep = 4;
                  case StudentStatus.arrivedHome:
                    currentStep = 5;
                  // Legacy fallbacks
                  case StudentStatus.onBus:
                    currentStep = student.suggestedDirection == 'to_home' ? 4 : 2;
                  case StudentStatus.atHome:
                    currentStep = student.suggestedDirection == 'to_home' ? 5 : 1;
                  case StudentStatus.late:
                    currentStep = 1;
                }

                String formatTime(int step, DateTime? time, bool reached, bool active) {
                  if (time != null) return DateFormat('hh:mm a').format(time);
                  if (active) return DateFormat('hh:mm a').format(DateTime.now());
                  
                  return '--:--';
                }

                return Row(
                  children: [
                    // Step 1: Waiting at home
                    _TimelineStep(
                      label: context.t('atHome'),
                      time: formatTime(1, student.waitingAtHomeTime, currentStep >= 1, currentStep == 1),
                      isActive: currentStep == 1,
                      isCompleted: currentStep > 1,
                      isDark: isDark,
                      stepIcon: Icons.home_rounded,
                    ),
                    Expanded(child: _TimelineConnector(isCompleted: currentStep > 1, isDark: isDark)),

                    // Step 2: On bus to school
                    _TimelineStep(
                      label: context.t('onBus'),
                      time: formatTime(2, student.onBusToSchoolTime, currentStep >= 2, currentStep == 2),
                      isActive: currentStep == 2,
                      isCompleted: currentStep > 2,
                      isDark: isDark,
                      stepIcon: Icons.directions_bus_rounded,
                    ),
                    Expanded(child: _TimelineConnector(isCompleted: currentStep > 2, isDark: isDark)),

                    // Step 3: At school
                    _TimelineStep(
                      label: context.t('atSchool'),
                      time: formatTime(3, student.atSchoolTime, currentStep >= 3, currentStep == 3),
                      isActive: currentStep == 3,
                      isCompleted: currentStep > 3,
                      isDark: isDark,
                      stepIcon: Icons.school_rounded,
                    ),
                    Expanded(child: _TimelineConnector(isCompleted: currentStep > 3, isDark: isDark)),

                    // Step 4: On bus to home
                    _TimelineStep(
                      label: context.t('onBus'),
                      time: formatTime(4, student.onBusToHomeTime, currentStep >= 4, currentStep == 4),
                      isActive: currentStep == 4,
                      isCompleted: currentStep > 4,
                      isDark: isDark,
                      stepIcon: Icons.directions_bus_rounded,
                    ),
                    Expanded(child: _TimelineConnector(isCompleted: currentStep > 4, isDark: isDark)),

                    // Step 5: Arrived home
                    _TimelineStep(
                      label: context.t('atHome'),
                      time: formatTime(5, student.arrivedHomeTime, currentStep >= 5, currentStep == 5),
                      isActive: currentStep == 5,
                      isCompleted: currentStep == 5, // Final step is green when active
                      isDark: isDark,
                      stepIcon: Icons.home_rounded,
                    ),
                  ],
                );
              },
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isActive || isCompleted
                ? [
                    BoxShadow(
                      color: circleColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isCompleted ? Icons.check_rounded : stepIcon,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive || isCompleted
                ? FontWeight.bold
                : FontWeight.w500,
            color: isDark
                ? (isActive || isCompleted ? Colors.white : Colors.white54)
                : (isActive || isCompleted
                      ? AppColors.textPrimary
                      : AppColors.textSecondary),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 9,
            color: isDark
                ? Colors.white38
                : AppColors.textSecondary.withValues(alpha: 0.7),
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}
