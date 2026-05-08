import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/utils/date_utils.dart'
    as date_utils;
import 'package:msaratwasel_user/src/shared/utils/notification_utils.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

enum _Filter { all, bus, student, school, supervisor }

class _NotificationsPageState extends State<NotificationsPage> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = controller.notifications.where((n) {
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.bus:
          return [
            NotificationType.approach,
            NotificationType.arrival,
            NotificationType.delay,
            NotificationType.routeChange,
          ].contains(n.type);
        case _Filter.student:
          return [
            NotificationType.checkIn,
            NotificationType.checkOut,
            NotificationType.lateBoarding,
            NotificationType.absence,
          ].contains(n.type);
        case _Filter.school:
          return n.type == NotificationType.schoolAlert;
        case _Filter.supervisor:
          return n.type == NotificationType.supervisorMessage;
      }
    }).toList()..sort((a, b) => b.time.compareTo(a.time));

    // Convert filter chips to widget
    final filterChips = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _buildFilterChip(context, _Filter.all, context.t('typeAll')),
          _buildFilterChip(context, _Filter.bus, context.t('bus')),
          _buildFilterChip(
            context,
            _Filter.student,
            context.t('student'),
          ),
          _buildFilterChip(
            context,
            _Filter.school,
            context.t('schoolInfo'), // Or add a better key
          ),
          _buildFilterChip(
            context,
            _Filter.supervisor,
            context.t('supervisor'),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadNotificationsFromApi();
        },
        color: isDark
            ? Theme.of(context).colorScheme.secondary
            : AppColors.primary,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                context.t('notifications'),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  width: 0.0,
                ),
              ),
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
              trailing: controller.notifications.any((n) => !n.read)
                  ? TextButton(
                      onPressed: () => controller.markNotificationsRead(),
                      child: Text(context.t('markAllRead')),
                    )
                  : null,
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  filterChips,
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 52,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.t('noNotifications'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.t('notificationsFooter'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = filtered[index];
                        final label = context.t('notification_${item.type.name}');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Card(
                            color: item.read
                                ? Theme.of(context).cardColor
                                : AppColors.primary.withAlpha(12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDark
                                    ? Colors.white.withAlpha(20)
                                    : AppColors.primary.withAlpha(30),
                                child: Icon(
                                  item.type.icon,
                                  color: isDark
                                      ? AppColors.dark.accent
                                      : AppColors.primary,
                                ),
                              ),
                              title: Text(label),
                              subtitle: Text(item.body),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    date_utils.timeAgo(
                                      item.time,
                                      locale: controller.locale.languageCode,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  if (!item.read)
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: AppColors.accent,
                                    ),
                                ],
                              ),
                              onTap: () =>
                                  controller.markNotificationsRead([item.id]),
                            ),
                          ),
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
            // Add bottom padding
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, _Filter filter, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
      selectedColor: isDark
          ? AppColors.dark.accent.withAlpha(40)
          : AppColors.primary.withAlpha(30),
      checkmarkColor: isDark ? Colors.white : AppColors.primary,
    );
  }
}
