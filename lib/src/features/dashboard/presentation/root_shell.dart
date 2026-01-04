import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/absence_request_page.dart';
import 'package:msaratwasel_user/src/features/children/presentation/children_screen.dart';
import 'package:msaratwasel_user/src/features/home/presentation/home_screen.dart';
import 'package:msaratwasel_user/src/features/messages/presentation/messages_page.dart';
import 'package:msaratwasel_user/src/features/notifications/presentation/notifications_page.dart';
import 'package:msaratwasel_user/src/features/profile/presentation/parent_profile_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/more_page.dart';
import 'package:msaratwasel_user/src/features/tracking/presentation/tracking_page.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';

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
    _pages = List<Widget?>.filled(8, null, growable: false);
    // Preload the first tab only to avoid initializing heavy widgets (e.g., Google Maps) prematurely.
    _pages[0] = const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isArabic = controller.locale.languageCode == 'ar';
        final currentIndex = controller.navIndex.clamp(0, _pages.length - 1);
        final page = _buildPage(currentIndex);

        return Scaffold(
          key: _scaffoldKey,

          drawer: CustomDrawer(
            controller: controller,
            currentIndex: currentIndex,
            isArabic: isArabic,
            onSelect: (index) {
              controller.setNavIndex(index);
              // Close drawer after selection
              if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              }
            },
          ),

          // AppBar removed to allow pages to have their own CupertinoSliverNavigationBar
          appBar: null,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // Keep SafeArea for scrollable pages (unified status/app bar color),
          // but allow TrackingPage (Google Maps) to be truly fullscreen.
          body: currentIndex == 2
              ? page
              : SafeArea(top: true, bottom: false, child: page),
        );
      },
    );
  }

  Widget _buildPage(int index) {
    // Lazily instantiate pages to avoid initializing platform views (e.g., Google Maps) when not visible.
    _pages[index] ??= switch (index) {
      0 => const HomeScreen(),
      1 => const ChildrenScreen(),
      2 => const TrackingPage(),
      3 => const NotificationsPage(),
      4 => const MessagesPage(),
      5 => const AbsenceRequestPage(),
      6 => const ParentProfilePage(),
      7 => const MorePage(),
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
    required this.isArabic,
    required this.onSelect,
  });

  final AppController controller;
  final int currentIndex;
  final bool isArabic;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Premium: Dark text for light mode, White text for dark mode
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final drawerBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
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
                      onTap: () => onSelect(6), // Profile
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
                            child: const CircleAvatar(
                              radius: 42,
                              backgroundImage: NetworkImage(
                                "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400",
                              ),
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
                      "عبدالله الأحمد",
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
                        "ولي الأمر",
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
                    title: "الرئيسية",
                    icon: Icons.home_rounded,
                    isSelected: currentIndex == 0,
                    isDark: isDark,
                    onTap: () => onSelect(0),
                  ),
                  _DrawerItem(
                    title: "الأبناء",
                    icon: Icons.family_restroom_rounded,
                    isSelected: currentIndex == 1,
                    isDark: isDark,
                    onTap: () => onSelect(1),
                  ),
                  _DrawerItem(
                    title: "تتبع الحافلة",
                    icon: Icons.directions_bus_rounded,
                    isSelected: currentIndex == 2,
                    isDark: isDark,
                    onTap: () => onSelect(2),
                  ),
                  _DrawerItem(
                    title: "الإشعارات",
                    icon: Icons.notifications_active_rounded,
                    isSelected: currentIndex == 3,
                    isDark: isDark,
                    onTap: () => onSelect(3),
                  ),
                  _DrawerItem(
                    title: "الدردشة",
                    icon: Icons.chat_bubble_rounded,
                    isSelected: currentIndex == 4,
                    isDark: isDark,
                    onTap: () => onSelect(4),
                  ),
                  _DrawerItem(
                    title: "إدارة الحضور",
                    icon: Icons.calendar_month_rounded,
                    isSelected: currentIndex == 5,
                    isDark: isDark,
                    onTap: () => onSelect(5),
                  ),
                  _DrawerItem(
                    title: "الإعدادات",
                    icon: Icons.settings_rounded,
                    isSelected: currentIndex == 7,
                    isDark: isDark,
                    onTap: () => onSelect(7),
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
                    // Logout logic
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 22),
                  label: const Text(
                    "تسجيل الخروج",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
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
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

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
          trailing: isSelected
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
