import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_screen.dart';
import 'package:msaratwasel_user/src/core/utils/logger.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/children/presentation/pages/children_status_page.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/pages/request_absence_page.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:msaratwasel_user/src/features/children/presentation/children_screen.dart';
import 'package:msaratwasel_user/src/features/home/presentation/home_screen.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/contacts_page.dart';
import 'package:msaratwasel_user/src/features/notifications/presentation/notifications_page.dart';
import 'package:msaratwasel_user/src/features/profile/presentation/parent_profile_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/more_page.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/pages/bus_tracking_page.dart';
import 'package:msaratwasel_user/src/features/location_requests/presentation/pages/location_requests_page.dart';

import 'package:msaratwasel_user/src/features/absence/presentation/pages/absence_history_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/section_badge.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(12, null, growable: false);
    // Preload the first tab only to avoid initializing heavy widgets (e.g., Google Maps) prematurely.
    _pages[0] = const HomeScreen();
  }

  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    AppLogger.d('🏠 RootShell: building');
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Handle Deep Linking / Notification Redirects
        if (controller.pendingNotificationId != null) {
          // Invalidate cached pages that handle deep-links to ensure they re-initialize and consume the ID
          _pages[4] = null;  // Notifications
          _pages[10] = null; // Absence History
          _pages[11] = null; // Location Requests
        }

        final currentIndex = controller.navIndex.clamp(0, _pages.length - 1);
        AppLogger.d('🏠 RootShell: current index = $currentIndex');
        final page = _buildPage(currentIndex);

        return PopScope(
          canPop: false, // Fully control back button behavior
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // 1. If not on Home (index 0), go back according to history
            if (currentIndex != 0) {
              controller.moveBack();
              return;
            }

            // 2. If we ARE on the Home tab, check for double-press to exit.
            final now = DateTime.now();
            final backButtonHasNotBeenPressedOrTimeHasExpired =
                _lastPressedAt == null ||
                now.difference(_lastPressedAt!) > const Duration(seconds: 2);

            if (backButtonHasNotBeenPressedOrTimeHasExpired) {
              _lastPressedAt = now;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.t('pressAgainToExit'),
                    textAlign: TextAlign.center,
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              return;
            }

            // 3. If pressed again within 2 seconds, exit the app properly.
            SystemNavigator.pop();
          },
          child: Scaffold(
            key: _scaffoldKey,
            drawer: CustomDrawer(
              controller: controller,
              currentIndex: currentIndex,
              onSelect: (index) {
                controller.setNavIndex(index);
                // Close drawer after selection
                if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                  Navigator.of(context).pop();
                }
              },
            ),
            appBar: null,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: controller.hasMissingLocation
                ? MissingLocationView(
                    students: controller.students
                        .where((s) => !s.hasLocation)
                        .toList(),
                  )
                : currentIndex == 2
                    ? page
                    : SafeArea(top: true, bottom: false, child: page),
          ),
        );
      },
    );
  }

  Widget _buildPage(int index) {
    // Lazily instantiate pages to avoid initializing platform views (e.g., Google Maps) when not visible.
    _pages[index] ??= switch (index) {
      0 => const HomeScreen(),
      1 => const ChildrenScreen(),
      2 => const BusTrackingPage(),
      3 => const ChildrenStatusPage(), // New Page
      4 => const NotificationsPage(),
      5 => const ContactsPage(),
      6 => const RequestAbsencePage(),
      7 => const AttendanceHistoryPage(),
      8 => const ParentProfilePage(),
      9 => const MorePage(),
      10 => const AbsenceHistoryPage(),
      11 => const LocationRequestsPage(),
      _ => const HomeScreen(),
    };
    return _pages[index]!;
  }
}

///////////////////////////////////////////////////////////////////////////////
///
///                ✨ Premium Drawer Refactored (Best Standards) ✨
///
/// ///////////////////////////////////////////////////////////////////////////

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.onSelect,
  });

  final AppController controller;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    AppLogger.d('🏠 RootShell: building');
    final controller = AppScope.of(context);

    // Premium: Dark text for light mode, White text for dark mode
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final drawerBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Drawer(
      elevation: 10,
      backgroundColor: drawerBg,
      // Premium: Rounded corners on the end
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------- HEADER ----------------
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xxl + 10,
            ),
            // Unified Background: No gradient, matches drawerBg
            decoration: BoxDecoration(
              color: drawerBg,
              borderRadius: const BorderRadiusDirectional.only(
                bottomEnd: Radius.circular(30),
              ),
              // Optional: Subtle separation if needed, or completely flat
              // border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  InkWell(
                    onTap: () => onSelect(8), // Profile (Updated Index)
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Border color adapted
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : AppColors.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            backgroundImage: controller.userAvatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    controller.userAvatarUrl,
                                    headers: controller.token.isNotEmpty
                                        ? {
                                            'Authorization':
                                                'Bearer ${controller.token}',
                                          }
                                        : null,
                                  )
                                : null,
                            child: controller.userAvatarUrl.isEmpty
                                ? Text(
                                    controller.userName.isNotEmpty
                                        ? controller.userName.characters.first
                                        : '?',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.primary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    controller.userName,
                    style: TextStyle(
                      color: textColor, // Adaptive Color
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.t('guardianRole'),
                      style: TextStyle(
                        color: subTextColor, // Adaptive Color
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------- MENU ----------------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xl,
                horizontal: AppSpacing.md,
              ),
              children: [
                _DrawerItem(
                  title: context.t('home'),
                  icon: Icons.home_rounded,
                  isSelected: currentIndex == 0,
                  isDark: isDark,
                  onTap: () => onSelect(0),
                ),
                _DrawerItem(
                  title: context.t('myKids'),
                  icon: Icons.family_restroom_rounded,
                  isSelected: currentIndex == 1,
                  isDark: isDark,
                  onTap: () => onSelect(1),
                ),
                _DrawerItem(
                  title: context.t('busTracking'),
                  icon: Icons.directions_bus_rounded,
                  isSelected: currentIndex == 2,
                  isDark: isDark,
                  onTap: () => onSelect(2),
                ),
                _DrawerItem(
                  title: context.t('childrenStatus'),
                  icon: Icons.timeline_rounded,
                  isSelected: currentIndex == 3,
                  isDark: isDark,
                  onTap: () => onSelect(3),
                ),
                _DrawerItem(
                  title: context.t('notifications'),
                  icon: Icons.notifications_active_rounded,
                  isSelected: currentIndex == 4, // Shifted from 3
                  isDark: isDark,
                  badgeCount: controller.notificationsUnreadCount,
                  onTap: () => onSelect(4),
                ),
                _DrawerItem(
                  title: context.t('chat'),
                  icon: Icons.chat_bubble_rounded,
                  isSelected: currentIndex == 5, // Shifted from 4
                  isDark: isDark,
                  badgeCount: controller.chatUnreadCount,
                  onTap: () => onSelect(5),
                ),
                _DrawerItem(
                  title: context.t('requestAbsence'),
                  icon: Icons.edit_calendar_rounded,
                  isSelected: currentIndex == 6, // Shifted from 5
                  isDark: isDark,
                  onTap: () => onSelect(6),
                ),
                _DrawerItem(
                  title: context.t('attendanceHistory'),
                  icon: Icons.history_rounded,
                  isSelected: currentIndex == 7, // Shifted from 6
                  isDark: isDark,
                  onTap: () => onSelect(7),
                ),
                _DrawerItem(
                  title: context.t('absenceRequests'),
                  icon: Icons.assignment_turned_in_rounded,
                  isSelected: currentIndex == 10,
                  isDark: isDark,
                  badgeCount: controller.absenceUnreadCount,
                  onTap: () {
                    onSelect(10);
                    controller.markNotificationsReadByCategory('absence_history');
                  },
                ),
                _DrawerItem(
                  title: context.t('locationRequests'),
                  icon: Icons.location_history_rounded,
                  isSelected: currentIndex == 11,
                  isDark: isDark,
                  badgeCount: controller.locationUnreadCount,
                  onTap: () {
                    onSelect(11);
                    controller.markNotificationsReadByCategory('location_requests');
                  },
                ),
                _DrawerItem(
                  title: context.t('settings'),
                  icon: Icons.settings_rounded,
                  isSelected: currentIndex == 9, // Shifted from 8
                  isDark: isDark,
                  onTap: () => onSelect(9),
                ),
              ],
            ),
          ),

          // ---------------- LOGOUT ----------------
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SafeArea(
              top: false,
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.t('logout')),
                      content: Text(context.t('logoutConfirmationRequest')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.t('cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            controller.logout();
                          },
                          child: Text(
                            context.t('logout'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.redAccent[100]
                      : AppColors.error,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: (isDark ? Colors.redAccent[100]! : AppColors.error)
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  backgroundColor: isDark
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                icon: const Icon(Icons.logout_rounded, size: 22),
                label: Text(
                  context.t('logout'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    // 🎨 Design Decision: "Simple & Modern"
    // Use Soft Tints instead of Solid Blocks.
    // This feels lighter and more "app-like" than web-like buttons.

    // Light Mode: Very soft Primary Tint
    // Dark Mode: Very soft White/Accent Tint

    final Color backgroundColor = isSelected
        ? (isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.08))
        : Colors.transparent;

    final Color foregroundColor = isSelected
        ? (isDark ? AppColors.accent : AppColors.primary)
        : (isDark ? Colors.white70 : AppColors.textSecondary);

    final FontWeight fontWeight = isSelected
        ? FontWeight.w700
        : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 4,
      ), // Tighter spacing for "Simple" look
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          dense: true, // Compact
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Slightly smaller radius
          ),
          tileColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2, // Minimal vertical padding
          ),
          minLeadingWidth: 24, // Tighter icon-text gap
          leading: Icon(
            icon,
            color: foregroundColor,
            size: 22, // Slightly smaller icons
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: fontWeight,
              color: foregroundColor,
              fontSize: 14, // Modern sleek size
            ),
          ),
          // Clean: No trailing icon needed if the distinct color change is there
          trailing: badgeCount > 0
              ? SectionBadge(count: badgeCount)
              : isSelected
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: foregroundColor,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class MissingLocationView extends StatelessWidget {
  const MissingLocationView({super.key, required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = AppScope.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: AppColors.error,
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            context.t('mandatoryLocationTitle') ?? 'تحديد الموقع المنزل إلزامي',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('mandatoryLocationDesc') ??
                'يرجى تحديد موقع المنزل لكل ابن لضمان وصول الحافلة بدقة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final student = students[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: (student.avatarUrl != null &&
                                student.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(
                                student.avatarUrl!,
                                headers: controller.token.isNotEmpty
                                    ? {
                                        'Authorization':
                                            'Bearer ${controller.token}',
                                      }
                                    : null,
                              )
                            : null,
                        child: (student.avatarUrl == null ||
                                student.avatarUrl!.isEmpty)
                            ? Text(
                                student.getLocalizedName(controller.locale.languageCode).isNotEmpty 
                                  ? student.getLocalizedName(controller.locale.languageCode).characters.first 
                                  : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.getLocalizedName(controller.locale.languageCode),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              student.getLocalizedGrade(controller.locale.languageCode),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPickerScreen(
                                initialLocation: student.homeLocation,
                              ),
                            ),
                          );

                          if (context.mounted) Navigator.pop(context); // close loading

                          if (result != null && context.mounted) {
                            LatLng? location;
                            String? label;
                            String? note;

                            if (result is LatLng) {
                              location = result;
                            } else if (result is Map) {
                              location = result['location'] as LatLng?;
                              label = result['label'] as String?;
                              note = result['note'] as String?;
                            }

                            if (location != null) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              await controller.updateHomeLocationApi(
                                location,
                                studentId: student.id,
                                address: label,
                                note: note,
                              );

                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(context.t('setNow') ?? 'تحديد'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Logout button as a secondary option if they are stuck
          TextButton.icon(
            onPressed: () => controller.logout(),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text(context.t('logout') ?? 'تسجيل الخروج'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

