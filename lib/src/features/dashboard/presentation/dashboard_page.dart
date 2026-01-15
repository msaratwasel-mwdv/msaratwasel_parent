import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/utils/labels.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/contact_us_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isArabic = controller.locale.languageCode == 'ar';
        final unread = controller.notifications.where((n) => !n.read).length;
        final latest = controller.notifications.isNotEmpty
            ? controller.notifications.first
            : null;
        final students = controller.students;

        return RefreshIndicator(
          onRefresh: () async {
            // Simulate refresh
            await Future.delayed(const Duration(seconds: 1));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Platform.isAndroid
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          context.t('dashboardTitle'),
                          style: TextStyle(
                            height: 1.2,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      )
                    : Text(
                        context.t('dashboardTitle'),
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                leading: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.primary,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.translate_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: controller.toggleLanguage,
                    ),
                    IconButton(
                      icon: _BadgeIcon(
                        icon: Icons.notifications_active_rounded,
                        count: unread,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => controller.setNavIndex(2),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                    width: 0.0, // hide standard border usually
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WelcomeHeader(
                        isArabic: isArabic,
                        studentName: students.isNotEmpty
                            ? students.first.name
                            : 'Student', // TODO: Localize if needed, but it's a name
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ActivityCard(
                        isArabic: isArabic,
                        unread: unread,
                        latest: latest,
                        onViewAll: () => controller.setNavIndex(2),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: context.t('quickActionsTitle')),
                      const SizedBox(height: AppSpacing.sm),
                      _QuickServicesGrid(
                        onTrack: () => controller.setNavIndex(1),
                        onCanteen: () => controller.setNavIndex(4),
                        onKids: () => controller.setNavIndex(0),
                        onSupport: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContactUsPage(),
                          ),
                        ),
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(title: context.t('kidsTitle')),
                      const SizedBox(height: AppSpacing.sm),
                      if (students.isEmpty)
                        _EmptyStudentsCard(isArabic: isArabic)
                      else ...[
                        for (final student in students) ...[
                          _StudentCard(
                            student: student,
                            tracking: controller.trackingForStudent(student.id),
                            isArabic: isArabic,
                            onTrack: () {
                              final index = controller.students.indexOf(
                                student,
                              );
                              controller.selectStudent(index);
                              controller.setNavIndex(1);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      _BusInfoCard(
                        isArabic: isArabic,
                        student: controller.currentStudent,
                        tracking: controller.currentTracking,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(context.t('visitSchoolSite')),
                        ),
                      ),
                      // Add bottom padding for scroll content
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.isArabic, required this.studentName});

  final bool isArabic;
  final String studentName;

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
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(20),
            AppColors.accent.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${context.t('welcomeUser')} ${studentName.split(' ').first}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStudentsCard extends StatelessWidget {
  const _EmptyStudentsCard({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.person_add_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.t('noStudentsRegistered'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.t('addStudentToStart'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: Text(context.t('addChild')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.isArabic,
    required this.unread,
    required this.latest,
    required this.onViewAll,
  });

  final bool isArabic;
  final int unread;
  final AppNotification? latest;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('activitiesTitle'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.t('activitiesSubtitle'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  shape: const StadiumBorder(),
                ),
                onPressed: onViewAll,
                child: Text(
                  context.t('viewAll'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (latest != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withAlpha(30),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latest!.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          latest!.body,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: AppSpacing.md),
                    _Badge(count: unread),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickServicesGrid extends StatelessWidget {
  const _QuickServicesGrid({
    required this.onTrack,
    required this.onCanteen,
    required this.onKids,
    required this.onSupport,
    required this.isArabic,
  });

  final VoidCallback onTrack;
  final VoidCallback onCanteen;
  final VoidCallback onKids;
  final VoidCallback onSupport;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItemData(
        label: context.t('busTracking'),
        icon: Icons.directions_bus_rounded,
        onTap: onTrack,
      ),
      _QuickItemData(
        label: context.t('canteen'),
        icon: Icons.restaurant_rounded,
        onTap: onCanteen,
      ),
      _QuickItemData(
        label: context.t('myKids'),
        icon: Icons.group_rounded,
        onTap: onKids,
      ),
      _QuickItemData(
        label: context.t('support'),
        icon: Icons.support_agent_rounded,
        onTap: onSupport,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width > 640
            ? 4
            : width > 520
            ? 3
            : 2;

        return GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: count,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1,
          children: items.map((item) => _QuickServiceItem(data: item)).toList(),
        );
      },
    );
  }
}

class _QuickItemData {
  const _QuickItemData({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickServiceItem extends StatelessWidget {
  const _QuickServiceItem({required this.data});

  final _QuickItemData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.tracking,
    required this.isArabic,
    required this.onTrack,
  });

  final Student student;
  final TrackingSnapshot tracking;
  final bool isArabic;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canTrack =
        tracking.busState == BusState.enRoute && tracking.etaMinutes > 0;
    final etaText = canTrack
        ? '${tracking.etaMinutes} ${context.t('minutesSuffix')}'
        : context.t('notAvailable');
    final statusText = Labels.studentStatus(student.status, arabic: isArabic);
    final statusColors = _statusChipColors(student.status);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.border,
        ),
      ),
      elevation: 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withAlpha(18),
                  backgroundImage: student.avatarUrl != null
                      ? NetworkImage(student.avatarUrl!)
                      : null,
                  child: student.avatarUrl == null
                      ? Text(
                          student.name.characters.first,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusColors.background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: statusColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.t('etaLabel'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      etaText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${context.t('statusLabel')}: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    Labels.busState(tracking.busState, arabic: isArabic),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: canTrack ? onTrack : null,
                    icon: Icon(
                      canTrack
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                    ),
                    label: Text(
                      canTrack
                          ? context.t('trackBus')
                          : context.t('notAvailable'),
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

  _ChipColors _statusChipColors(StudentStatus status) {
    switch (status) {
      case StudentStatus.onBus:
        return const _ChipColors(
          background: Color(0xFFE0ECFF),
          text: Color(0xFF1E3A8A),
        );
      case StudentStatus.atSchool:
        return const _ChipColors(
          background: Color(0xFFDFF8E1),
          text: Color(0xFF166534),
        );
      case StudentStatus.atHome:
        return const _ChipColors(
          background: Color(0xFFF5E7D0),
          text: Color(0xFF92400E),
        );
      case StudentStatus.notBoarded:
        return const _ChipColors(
          background: Color(0xFFFFF4DE),
          text: Color(0xFF92400E),
        );
      case StudentStatus.late:
        return const _ChipColors(
          background: Color(0xFFFFE4E6),
          text: Color(0xFFB91C1C),
        );
    }
  }
}

class _BusInfoCard extends StatelessWidget {
  const _BusInfoCard({
    required this.isArabic,
    required this.student,
    required this.tracking,
  });

  final bool isArabic;
  final Student student;
  final TrackingSnapshot tracking;

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(
        icon: Icons.person_rounded,
        label: context.t('driverName'),
        value: isArabic ? 'عبدالله محمد' : 'Abdullah Mohammed',
      ),
      _InfoItem(
        icon: Icons.escalator_warning_rounded,
        label: context.t('assistantName'),
        value: isArabic ? 'مريم حسين' : 'Maryam Hussain',
      ),
      _InfoItem(
        icon: Icons.pin_drop_rounded,
        label: context.t('busNumber'),
        value: student.bus.number,
      ),
      _InfoItem(
        icon: Icons.confirmation_number_rounded,
        label: context.t('busPlate'),
        value: student.bus.plate,
      ),
      _InfoItem(
        icon: Icons.route_rounded,
        label: context.t('route'),
        value: tracking.routeDescription,
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.border,
        ),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('busInfoTitle'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              children: items.map((item) => _InfoRow(item: item)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  item.value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color),
        if (count > 0)
          Positioned(top: -4, right: -4, child: _Badge(count: count)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ChipColors {
  const _ChipColors({required this.background, required this.text});

  final Color background;
  final Color text;
}
