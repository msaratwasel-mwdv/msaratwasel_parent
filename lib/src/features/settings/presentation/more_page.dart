import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
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
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                context.t('settings'),
                style: TextStyle(
                  fontFamily: GoogleFonts.cairo().fontFamily,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.9),
              border: null, // Remove the border for a cleaner look
              stretch: true,
              leading: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(Icons.menu_rounded, color: AppColors.primary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'إعدادات التطبيق والحساب'
                          : 'App and account settings',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Account Section
                    _SectionHeader(title: isArabic ? 'الحساب' : 'Account'),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: PhosphorIcons.userCircle(
                            PhosphorIconsStyle.duotone,
                          ),
                          title: isArabic ? 'الملف الشخصي' : 'Profile',
                          subtitle: isArabic
                              ? 'تعديل البيانات الشخصية'
                              : 'Edit personal info',
                          onTap: () =>
                              controller.setNavIndex(6), // Parent Profile
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: PhosphorIcons.users(PhosphorIconsStyle.duotone),
                          title: isArabic ? 'أبنائي' : 'My Kids',
                          subtitle: isArabic
                              ? 'إدارة الطلاب المسجلين'
                              : 'Manage registered students',
                          onTap: () => controller.setNavIndex(0), // Kids list
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // App Settings Section
                    _SectionHeader(title: isArabic ? 'التطبيق' : 'Application'),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: isDark
                              ? PhosphorIcons.moonStars(
                                  PhosphorIconsStyle.duotone,
                                )
                              : PhosphorIcons.sun(PhosphorIconsStyle.duotone),
                          title: isArabic ? 'المظهر' : 'Appearance',
                          subtitle: isDark
                              ? (isArabic ? 'داكن' : 'Dark')
                              : (isArabic ? 'فاتح' : 'Light'),
                          trailing: Switch.adaptive(
                            value: isDark,
                            activeColor: AppColors.primary,
                            onChanged: (v) => controller.toggleTheme(isDark),
                          ),
                          onTap: () => controller.toggleTheme(isDark),
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: PhosphorIcons.translate(
                            PhosphorIconsStyle.duotone,
                          ),
                          title: isArabic ? 'الخ لغة' : 'Language',
                          subtitle: isArabic ? 'العربية' : 'English',
                          trailing: Switch.adaptive(
                            value: isArabic,
                            activeColor: AppColors.primary,
                            onChanged: (v) => controller.toggleLanguage(),
                          ),
                          onTap: controller.toggleLanguage,
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: PhosphorIcons.bellSimple(
                            PhosphorIconsStyle.duotone,
                          ),
                          title: isArabic ? 'الإشعارات' : 'Notifications',
                          subtitle: isArabic
                              ? 'تنبيهات الرحلات والحضور'
                              : 'Trip and attendance alerts',
                          trailing: Switch.adaptive(
                            value: notificationsEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (v) =>
                                setState(() => notificationsEnabled = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Support Section
                    _SectionHeader(title: isArabic ? 'الدعم' : 'Support'),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: PhosphorIcons.question(
                            PhosphorIconsStyle.duotone,
                          ),
                          title: isArabic ? 'مركز المساعدة' : 'Help Center',
                          onTap: () {},
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: PhosphorIcons.phoneCall(
                            PhosphorIconsStyle.duotone,
                          ),
                          title: isArabic ? 'تواصل معنا' : 'Contact Us',
                          onTap: () {},
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: PhosphorIcons.info(PhosphorIconsStyle.duotone),
                          title: isArabic ? 'عن التطبيق' : 'About App',
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
                          backgroundColor: AppColors.error.withOpacity(0.1),
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          isArabic ? 'تسجيل الخروج' : 'Logout',
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
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.border,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
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
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.08),
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
          ? Colors.white.withOpacity(0.05)
          : AppColors.border.withOpacity(0.5),
    );
  }
}
