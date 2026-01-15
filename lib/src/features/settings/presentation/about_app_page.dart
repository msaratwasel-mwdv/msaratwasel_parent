import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          AppSliverHeader(title: context.t('aboutApp')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Logo Area
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      // Assuming app icon asset exists, otherwise fallback to icon
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/msarticon/icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primary,
                              child: const Icon(
                                Icons.directions_bus_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // App Name & Version
                  Text(
                    context.t('appName'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.t('version')} 2.0.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // About App Description
                  _SectionCard(
                    title: context.t('aboutApp'),
                    content: context.t('aboutAppDescription'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // About Company Description
                  _SectionCard(
                    title: context.t('aboutCompanyTitle'),
                    content: context.t('aboutCompany'),
                    isDark: isDark,
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  const SizedBox(height: AppSpacing.xxl),

                  // Developer Credit
                  Column(
                    children: [
                      Text(
                        context.t('developedBy'),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.dark.accent.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.code_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.dark.accent
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Silicon Apex (SA)',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.dark.accent
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Extra padding at bottom
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.content,
    required this.isDark,
  });

  final String title;
  final String content;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: GoogleFonts.cairo(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
