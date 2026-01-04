import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/features/settings/presentation/change_password_page.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool notificationsEnabled = true;

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
                  color: Theme.of(context).primaryColor,
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
                            controller.setNavIndex(6), // Parent Profile
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
                        title: context.t('myKids'),
                        subtitle: context.t('manageKids'),
                        onTap: () => controller.setNavIndex(0), // Kids list
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
                        trailing: Switch.adaptive(
                          value: isDark,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => controller.toggleTheme(isDark),
                        ),
                        onTap: () => controller.toggleTheme(isDark),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.translate(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.t('language'),
                        subtitle: isArabic ? 'العربية' : 'English',
                        trailing: Switch.adaptive(
                          value: isArabic,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => controller.toggleLanguage(),
                        ),
                        onTap: controller.toggleLanguage,
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
                        onTap: () {},
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.info(PhosphorIconsStyle.duotone),
                        title: context.t('aboutApp'),
                        subtitle: 'v1.0.0',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.logout,
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
          color: isDark ? AppColors.primary : AppColors.primary,
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
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
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
