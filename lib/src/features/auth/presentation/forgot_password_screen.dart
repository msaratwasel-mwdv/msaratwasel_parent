import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/widgets/custom_text_field.dart';
import 'package:msaratwasel_user/src/shared/widgets/frosted_card.dart';
import 'package:msaratwasel_user/src/shared/widgets/primary_button.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/widgets/auth_background.dart';
import 'package:msaratwasel_user/src/shared/widgets/directional_icon.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _civilIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _civilIdController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final res = await widget.controller.forgotPassword(
      civilId: _civilIdController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: DirectionalIcon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            // 1. Background
            AuthBackground(isDark: isDark),

            // 2. Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .2),
                          ),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 64,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ).animate().fadeIn().scale(),

                      const SizedBox(height: 32),

                      FrostedCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.t('forgotPasswordTitle'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.t('forgotPasswordSubtitle'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 32),

                              CustomTextField(
                                    controller: _civilIdController,
                                    label: context.t('civilId'),
                                    icon: Icons.credit_card_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return context.t('civilIdError');
                                      }
                                      return null;
                                    },
                                  )
                                  .animate()
                                  .fadeIn(delay: 150.ms)
                                  .slideY(begin: 0.2),

                              const SizedBox(height: 24),

                              PrimaryButton(
                                    onTap: _handleReset,
                                    text: context.t('sendResetLink'),
                                    isLoading: _isLoading,
                                    icon: Icons.lock_reset_rounded,
                                  )
                                  .animate()
                                  .fadeIn(delay: 250.ms)
                                  .slideY(begin: 0.2),

                              const SizedBox(height: 16),

                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    context.t('backToLogin'),
                                    style: GoogleFonts.cairo(
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

// Reusing the background from LoginScreen to maintain consistency
