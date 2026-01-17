import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/features/children/presentation/location_picker_screen.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/utils/labels.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:url_launcher/url_launcher.dart';

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final students = controller.students;
    final attendance = controller.attendance;
    final trips = controller.trips;
    final isArabic = controller.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Navigation Bar
        // Navigation Bar
        AppSliverHeader(
          title: '${context.t('myKids')} (${students.length})',
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final student = students[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _ChildCard(
                  student: student,
                  isDark: isDark,
                  isArabic: isArabic,
                  onTap: () => _showChildDetails(
                    context,
                    student,
                    isDark,
                    isArabic,
                    attendance,
                    trips,
                  ),
                ),
              );
            }, childCount: students.length),
          ),
        ),
      ],
    );
  }

  void _showChildDetails(
    BuildContext context,
    Student student,
    bool isDark,
    bool isArabic,
    List<AttendanceEntry> attendance,
    List<TripEntry> trips,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChildDetailsSheet(
        student: student,
        isDark: isDark,
        isArabic: isArabic,
        attendance: attendance,
        trips: trips,
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.student,
    required this.isDark,
    required this.isArabic,
    required this.onTap,
  });

  final Student student;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final statusText = Labels.studentStatus(student.status, arabic: isArabic);
    final statusIcon = _statusIcon(student.status);
    final statusColor = _getStatusColor(student.status, isDark);

    // Mock data for attendance and trips
    final attendancePercentage = student.id == 'st-1' ? 95 : 98;
    final totalTrips = student.id == 'st-1' ? 142 : 156;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Name + Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        student.name[0],
                        style: TextStyle(
                          color: isDark ? AppColors.primary : AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
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
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.t('studentGrade')}: ${student.grade} • ${student.schoolId}',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
              Divider(
                color: isDark
                    ? Colors.white12
                    : Colors.grey.withValues(alpha: 0.2),
              ),
              const SizedBox(height: AppSpacing.md),

              // Current Status
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${context.t('bus')} ${student.bus.number} • ${student.bus.plate}',
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
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              Divider(
                color: isDark
                    ? Colors.white12
                    : Colors.grey.withValues(alpha: 0.2),
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.check_circle_outline,
                      label: context.t('attendance'),
                      value: '$attendancePercentage%',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.route_rounded,
                      label: context.t(
                        'tripsHistory',
                      ), // or "Trips", using tripsHistory
                      value: totalTrips.toString(),
                      color: AppColors.accent,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.directions_bus_rounded,
                      label: context.t('track'),
                      color: AppColors.accent,
                      isDark: isDark,
                      onTap: () {
                        // TODO: Since we are in a list, finding the index of 'student' in the full list
                        // is required if `students` here is filtered. Assuming `students` comes directly from controller order.
                        final index = controller.students.indexOf(student);
                        if (index != -1) {
                          controller.selectStudent(index);
                          controller.setNavIndex(2);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.calendar_month_rounded,
                      label: context.t('attendance'),
                      color: Colors.orange,
                      isDark: isDark,
                      onTap: () => controller.setNavIndex(7),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.person_outline,
                      label: context.t('file'),
                      color: isDark ? Colors.white : AppColors.primary,
                      isDark: isDark,
                      onTap: onTap,
                    ),
                  ),
                ],
              ),
            ],
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
      return Colors.white; // Ensure "At School" is white in Dark Mode
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildDetailsSheet extends StatelessWidget {
  const _ChildDetailsSheet({
    required this.student,
    required this.isDark,
    required this.isArabic,
    required this.attendance,
    required this.trips,
  });

  final Student student;
  final bool isDark;
  final bool isArabic;
  final List<AttendanceEntry> attendance;
  final List<TripEntry> trips;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      student.name[0],
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.t('studentGrade')}: ${student.grade} • ${student.schoolId}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Bus Information
                _DetailSection(
                  title: context.t('busInfoTitle'),
                  icon: Icons.directions_bus_rounded,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _DetailRow(
                        label: context.t('busNumber'),
                        value: student.bus.number,
                        isDark: isDark,
                      ),
                      _DetailRow(
                        label: context.t('busPlate'),
                        value: student.bus.plate,
                        isDark: isDark,
                      ),
                      _DetailRow(
                        label: context.t('statusLabel'),
                        value: Labels.studentStatus(
                          student.status,
                          arabic: isArabic,
                        ),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Home Location
                _DetailSection(
                  title: context.t('homeLocation'),
                  icon: Icons.location_on_rounded,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.homeLocation != null
                                      ? '${student.homeLocation!.latitude.toStringAsFixed(4)}, ${student.homeLocation!.longitude.toStringAsFixed(4)}'
                                      : context.t('notAvailable'),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (student.locationNote != null &&
                                    student.locationNote!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    student.locationNote!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.map_rounded, size: 22),
                            color: isDark ? Colors.white : AppColors.primary,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationPickerScreen(
                                    initialLocation: student.homeLocation,
                                    isReadOnly: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // School Information
                _DetailSection(
                  title: context.t('schoolInfo'),
                  icon: Icons.school_rounded,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'مدارس الأقصى الأهلية'
                            : 'Al Aqsa Private Schools',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Mock Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'الرياض، حي الملقا'
                                  : 'Riyadh, Al Malqa Dist.',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Bus Driver Info
                _DetailSection(
                  title: context.t('busDriver'),
                  icon: Icons.airline_seat_recline_normal_rounded,
                  isDark: isDark,
                  child: _ContactInfoRow(
                    name: isArabic ? 'محمد عبدالله' : 'Mohammed Abdullah',
                    phone: '0551234567',
                    avatarUrl:
                        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
                    isDark: isDark,
                    context: context,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Bus Supervisor Info
                _DetailSection(
                  title: context.t('busSupervisor'),
                  icon: Icons.verified_user_rounded,
                  isDark: isDark,
                  child: _ContactInfoRow(
                    name: isArabic ? 'سارة خالد' : 'Sara Khalid',
                    phone: '0509876543',
                    avatarUrl:
                        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
                    isDark: isDark,
                    context: context,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  const _ContactInfoRow({
    required this.name,
    required this.phone,
    required this.avatarUrl,
    required this.isDark,
    required this.context,
  });

  final String name;
  final String phone;
  final String avatarUrl;
  final bool isDark;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
          final uri = Uri.parse('tel:$cleanPhone');
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('Error launching call: $e');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.phone_in_talk_rounded,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
