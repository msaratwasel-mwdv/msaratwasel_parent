import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _complaintController = TextEditingController();

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch \$url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      debugPrint('Could not launch \$launchUri');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(launchUri)) {
      debugPrint('Could not launch \$launchUri');
    }
  }

  void _submitComplaint() {
    if (_complaintController.text.trim().isEmpty) return;

    // Simulate API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.t('complaintSent')),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _complaintController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Determine theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          AppSliverHeader(title: context.t('contactUs')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // --- Contact Methods Section ---
                  _SectionHeader(title: context.t('contactMethods')),
                  const SizedBox(height: AppSpacing.md),

                  // Phone
                  _ContactCard(
                    icon: PhosphorIcons.phoneCall(PhosphorIconsStyle.duotone),
                    title: context.t('phoneNumber'),
                    value: '920000000', // Example number
                    onTap: () => _makePhoneCall('920000000'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Email
                  _ContactCard(
                    icon: PhosphorIcons.envelopeSimple(
                      PhosphorIconsStyle.duotone,
                    ),
                    title: context.t('email'),
                    value: 'info@msarat.sa', // Example email
                    onTap: () => _sendEmail('info@msarat.sa'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Website
                  _ContactCard(
                    icon: PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                    title: context.t('website'),
                    value: 'www.msarat.sa', // Example website
                    onTap: () => _launchUrl('https://www.msarat.sa'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // --- Social Media Section ---
                  _SectionHeader(title: context.t('socialMedia')),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SocialButton(
                        icon: PhosphorIcons.twitterLogo(
                          PhosphorIconsStyle.fill,
                        ),
                        label: 'Twitter',
                        color: const Color(0xFF1DA1F2),
                        onTap: () => _launchUrl('https://twitter.com/msarat'),
                        isDark: isDark,
                      ),
                      _SocialButton(
                        icon: PhosphorIcons.instagramLogo(
                          PhosphorIconsStyle.fill,
                        ),
                        label: 'Instagram',
                        color: const Color(0xFFE1306C),
                        onTap: () => _launchUrl('https://instagram.com/msarat'),
                        isDark: isDark,
                      ),

                      _SocialButton(
                        icon: PhosphorIcons.facebookLogo(
                          PhosphorIconsStyle.fill,
                        ),
                        label: 'Facebook',
                        color: const Color(0xFF4267B2),
                        onTap: () => _launchUrl('https://facebook.com/msarat'),
                        isDark: isDark,
                      ),
                      _SocialButton(
                        icon: PhosphorIcons.whatsappLogo(
                          PhosphorIconsStyle.fill,
                        ),
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _launchUrl('https://wa.me/966500000000'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // --- Complaints Box Section ---
                  _SectionHeader(title: context.t('complaintsBox')),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _complaintController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: context.t('complaintMessageHint'),
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.black26
                                : Colors.grey.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _submitComplaint,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 20),
                          label: Text(
                            context.t('submit'), // or 'send' if added
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDark ? Colors.white : AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.dark.accent.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.dark.accent : AppColors.primary,
                  size: 24,
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
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark
                    ? Colors.white24
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
