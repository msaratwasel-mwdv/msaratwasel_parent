import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(title: context.t('privacyPolicy'), hasLeading: true),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(
                  title: context.t('privacyIntroTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyIntroBody1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyIntroBody2'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: context.t('privacyDataCollectionTitle'),
                  isDark: isDark,
                ),
                _SubTitle(
                  title: context.t('privacyStudentDataTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyStudentData1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyStudentData2'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyStudentData3'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyStudentData4'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyStudentData5'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyStudentData6'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyStudentData7'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
                _SubTitle(
                  title: context.t('privacyOtherDataTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyOtherData1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyOtherData2'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyOtherData3'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: context.t('privacyDataUsageTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataUsage1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataUsage2'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataUsage3'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataUsage4'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataUsage5'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: context.t('privacyDataProtectionTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataProtection1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataProtection2'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataProtection3'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyDataProtection4'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: context.t('privacyUserRightsTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyUserRights1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyUserRights2'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyUserRights3'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: context.t('privacyUserObligationsTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyUserObligations1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyUserObligations2'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyUserObligations3'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: context.t('privacyLegalLiabilityTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyLegalLiability1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyLegalLiability2'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyLegalLiability3'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: context.t('privacyAmendmentsTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyAmendments1'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyAmendments2'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: context.t('privacyConsentTitle'),
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: context.t('privacyConsentBody'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                _SectionTitle(
                  title: context.t('privacySimplifiedTitle'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
                _QuestionAnswer(
                  question: context.t('privacyQ1'),
                  answer: context.t('privacyA1'),
                  isDark: isDark,
                ),
                _QuestionAnswer(
                  question: context.t('privacyQ2'),
                  answer: context.t('privacyA2'),
                  isDark: isDark,
                ),
                _QuestionAnswer(
                  question: context.t('privacyQ3'),
                  answer: context.t('privacyA3'),
                  isDark: isDark,
                ),
                _QuestionAnswer(
                  question: context.t('privacyQ4'),
                  answer: context.t('privacyA4'),
                  isDark: isDark,
                ),
                _QuestionAnswer(
                  question: context.t('privacyQ5'),
                  answer: context.t('privacyA5'),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.primary,
        height: 1.6,
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, right: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(
              Icons.circle,
              size: 6,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionAnswer extends StatelessWidget {
  const _QuestionAnswer({
    required this.question,
    required this.answer,
    required this.isDark,
  });
  final String question;
  final String answer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.dark.accent : AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
