import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/change_password_page.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/privacy_policy_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/contact_us_page.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/about_app_page.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_user/src/features/children/presentation/location_picker_screen.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool notificationsEnabled = true;

  void _showStudentSelectionSheet(BuildContext context) {
    final controller = AppScope.of(context);
    final students = controller.students;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.t('selectChildToChangeLocation'),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ...students.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  onTap: () async {
                    Navigator.pop(context); // Close sheet
                    // Navigate to Location Picker
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerScreen(
                          initialLocation: student.homeLocation,
                        ),
                      ),
                    );

                    if (result != null && context.mounted) {
                      if (result is Map) {
                        final location = result['location'] as LatLng;
                        final note = result['note'] as String?;
                        controller.updateStudentLocation(
                          student.id,
                          location,
                          note: note,
                        );
                      } else if (result is LatLng) {
                        controller.updateStudentLocation(student.id, result);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.t('locationUpdated')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      student.name[0],
                      style: GoogleFonts.cairo(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${context.t('studentGrade')}: ${student.grade}',
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? Colors.white12 : AppColors.border,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isArabic = controller.locale.languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          AppSliverHeader(
            title: context.t('settings'),
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
          ), // Unified header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... existing header ...
                  const SizedBox(height: AppSpacing.xl),

                  // Account Section
                  _SectionHeader(title: context.t('account')),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIcons.userCircle(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.t('profile'),
                        subtitle: context.t('editProfile'),
                        onTap: () =>
                            controller.setNavIndex(8), // Parent Profile
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.lockKey(PhosphorIconsStyle.duotone),
                        title: context.t('changePassword'),
                        subtitle: '********',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.users(PhosphorIconsStyle.duotone),
                        title: context.t('changeChildrenLocation'),
                        subtitle: context.t('manageKids'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                context.t('locationChangeWarningTitle'),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                context.t('locationChangeWarningBody'),
                                style: GoogleFonts.cairo(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    context.t('cancel'),
                                    style: GoogleFonts.cairo(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close warning
                                    _showStudentSelectionSheet(context);
                                  },
                                  child: Text(
                                    context.t('proceed'),
                                    style: GoogleFonts.cairo(
                                      color: isDark
                                          ? AppColors.dark.accent
                                          : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // App Settings Section
                  _SectionHeader(title: context.t('application')),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: isDark
                            ? PhosphorIcons.moonStars(
                                PhosphorIconsStyle.duotone,
                              )
                            : PhosphorIcons.sun(PhosphorIconsStyle.duotone),
                        title: context.t('appearance'),
                        subtitle: isDark
                            ? context.t('dark')
                            : context.t('light'),
                        trailing: _SegmentedToggle(
                          value: isDark,
                          onChanged: (v) {
                            if (v != isDark) controller.toggleTheme(isDark);
                          },
                          leftLabel: context.t('light'),
                          rightLabel: context.t('dark'),
                          leftIcon: PhosphorIcons.sun(PhosphorIconsStyle.bold),
                          rightIcon: PhosphorIcons.moonStars(
                            PhosphorIconsStyle.bold,
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.translate(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.t('language'),
                        // Subtitle removed to avoid redundancy with the toggle
                        trailing: _SegmentedToggle(
                          value:
                              !isArabic, // False (Left) = Arabic, True (Right) = English
                          onChanged: (targetIsEnglish) {
                            // If target matches current isArabic state (e.g. Target English(true) and isArabic(true)), it means we need to toggle
                            if (targetIsEnglish == isArabic) {
                              controller.toggleLanguage();
                            }
                          },
                          leftLabel: 'العربية',
                          rightLabel: 'English',
                          leftIcon: PhosphorIcons.translate(
                            PhosphorIconsStyle.bold,
                          ),
                          rightIcon: PhosphorIcons.textAa(
                            PhosphorIconsStyle.bold,
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.bellSimple(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.t('notifications'),
                        subtitle: context.t('activitiesSubtitle'),
                        trailing: Switch.adaptive(
                          value: notificationsEnabled,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => notificationsEnabled = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Support Section
                  _SectionHeader(title: context.t('support')),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIcons.question(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.t('helpCenter'),
                        onTap: () {},
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.phoneCall(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.t('contactUs'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContactUsPage(),
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.info(PhosphorIconsStyle.duotone),
                        title: context.t('aboutApp'),
                        subtitle: 'v2.0.0',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutAppPage(),
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.shieldCheck(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.t('privacyPolicy'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(context.t('logout')),
                            content: Text(
                              context.t('logoutConfirmationRequest'),
                            ),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        context.t('logout'),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacing.xxl,
                  ), // Extra space for bottom nav
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.border,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white60
                              : AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppColors.border.withValues(alpha: 0.5),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftIcon,
    required this.rightIcon,
  });

  final bool value; // false = left, true = right
  final ValueChanged<bool> onChanged;
  final String leftLabel;
  final String rightLabel;
  final IconData leftIcon;
  final IconData rightIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFFF1F5F9), // Lighter, cleaner grey
        borderRadius: BorderRadius.circular(16), // Softer corners
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegment(
            context: context,
            isSelected: !value,
            label: leftLabel,
            icon: leftIcon,
            onTap: () => onChanged(false),
          ),
          // Removed SizedBox to allow segments to touch/flow better if needed,
          // or keep it small. keeping it but smaller for tight fit.
          const SizedBox(width: 4),
          _buildSegment(
            context: context,
            isSelected: value,
            label: rightLabel,
            icon: rightIcon,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn, // More responsive feel
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // More horizontal padding
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.04,
                    ), // Very subtle shadow
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Only show icon if selected or for specific "simple" look?
            // User screenshot shows icons on both. Keeping icons.
            Icon(
              icon,
              size: 18, // Slightly larger
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.textPrimary)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
