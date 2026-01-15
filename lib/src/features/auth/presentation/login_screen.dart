import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/forgot_password_screen.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/widgets/custom_text_field.dart';
import 'package:msaratwasel_user/src/shared/widgets/frosted_card.dart';
import 'package:msaratwasel_user/src/shared/widgets/primary_button.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/widgets/auth_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _civilIdController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animC;

  @override
  void initState() {
    super.initState();
    _animC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animC.dispose();
    _civilIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _animC.forward(from: 0);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      final ok = await widget.controller.login(
        civilId: _civilIdController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (!mounted) return;
      if (!ok) setState(() => _errorMessage = context.t('loginError'));
    } catch (_) {
      if (mounted) setState(() => _errorMessage = context.t('connectionError'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDark;
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            // 1. Animated Background
            // 1. Animated Background
            AuthBackground(isDark: isDark),
            // 2. Glass Form
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _LoginHeader(),
                        const SizedBox(height: 40),
                        FrostedCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _title(context, isDark),
                              const SizedBox(height: 24),
                              CustomTextField(
                                controller: _civilIdController,
                                label: context.t('civilId'),
                                icon: Icons.credit_card_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.isNotEmpty == true
                                    ? null
                                    : context.t('civilIdError'),
                              ).animate().fadeIn(delay: 150.ms).scale(),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _phoneController,
                                label: context.t('phoneNumber'),
                                icon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v?.isNotEmpty == true
                                    ? null
                                    : context.t('phoneError'),
                              ).animate().fadeIn(delay: 250.ms).scale(),
                              const SizedBox(height: 8),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: () => _resetByPhone(context),
                                  child: Text(
                                    context.t('forgotData'),
                                    style: GoogleFonts.cairo(
                                      color: isDark
                                          ? AppColors.dark.accent
                                          : AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark
                                                ? AppColors.error
                                                : AppColors.error)
                                            .withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          (isDark
                                                  ? AppColors.error
                                                  : AppColors.error)
                                              .withValues(alpha: .3),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      color: isDark
                                          ? AppColors.error
                                          : AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ).animate(controller: _animC).shake().fadeIn(),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                isLoading: _isLoading,
                                onTap: _handleLogin,
                                text: context.t('login'),
                                icon: Icons.arrow_forward_rounded,
                              ),
                              const SizedBox(height: 16),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 3. Theme & Language toggles
            PositionedDirectional(
              top: 0,
              end: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircleIcon(
                        icon: isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        onTap: () => widget.controller.toggleTheme(isDark),
                      ),
                      const SizedBox(width: 12),
                      _CircleIcon(
                        icon: Icons.language_rounded,
                        onTap: () => widget.controller.toggleLanguage(),
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

  Widget _title(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    return Column(
      children: [
        Text(
          context.t('welcomeBack'),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.t('signInToContinue'),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    ).animate().fadeIn().moveY(begin: 10, end: 0);
  }

  void _resetByPhone(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(controller: widget.controller),
      ),
    );
  }
}

/* ==================== Widgets ==================== */

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'logo',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .2)),
            ),
            child: Image.asset('assets/icons/msarticon/icon.png', height: 90),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.t('appName'),
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ],
    ).animate().fadeIn().scale();
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .15),
      shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
