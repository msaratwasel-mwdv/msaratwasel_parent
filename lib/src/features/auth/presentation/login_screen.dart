import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final theme = isDark ? AppColors.dark : AppColors.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: theme.scaffold,
        child: Stack(
          children: [
            // 1. Animated Background
            _AnimatedBackground(dark: isDark),
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
                        _GlassCard(
                          dark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _title(theme),
                              const SizedBox(height: 24),
                              _PremiumTextField(
                                controller: _civilIdController,
                                label: context.t('civilId'),
                                icon: PhosphorIcons.identificationCard(
                                  PhosphorIconsStyle.regular,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.isNotEmpty == true
                                    ? null
                                    : context.t('civilIdError'),
                                dark: isDark,
                              ).animate().fadeIn(delay: 150.ms).scale(),
                              const SizedBox(height: 16),
                              _PremiumTextField(
                                controller: _phoneController,
                                label: context.t('phoneNumber'),
                                icon: PhosphorIcons.phone(
                                  PhosphorIconsStyle.regular,
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (v) => v?.isNotEmpty == true
                                    ? null
                                    : context.t('phoneError'),
                                dark: isDark,
                              ).animate().fadeIn(delay: 250.ms).scale(),
                              const SizedBox(height: 8),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: () => _resetByPhone(context),
                                  child: Text(
                                    context.t('forgot'),
                                    style: GoogleFonts.cairo(
                                      color: theme.accent,
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
                                    color: theme.error.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.error.withOpacity(.3),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      color: theme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ).animate(controller: _animC).shake().fadeIn(),
                              const SizedBox(height: 24),
                              _LoginButton(
                                loading: _isLoading,
                                onTap: _handleLogin,
                                dark: isDark,
                              ),
                              const SizedBox(height: 16),
                              if (Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'ar')
                                _BioButton(dark: isDark),
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

  Widget _title(AppThemeColors theme) => Column(
    children: [
      Text(
        context.t('welcomeBack'),
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: theme.text,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        context.t('signInToContinue'),
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(fontSize: 14, color: theme.text70),
      ),
    ],
  ).animate().fadeIn().moveY(begin: 10, end: 0);

  void _resetByPhone(BuildContext ctx) {
    // TODO: navigate to reset screen
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text(context.t('resetSoon'))));
  }
}

/* ==================== Widgets ==================== */

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        ),
      ),
      child: Stack(
        children: [
          // Orb 1
          Positioned(
                top: -100,
                right: -100,
                child: _orb(400, dark ? AppColors.accent : AppColors.primary),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15)),
          // Orb 2
          Positioned(
                bottom: -60,
                left: -60,
                child: _orb(320, dark ? Colors.blueAccent : Colors.cyanAccent),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(begin: Offset.zero, end: const Offset(30, -30)),
          // Glass blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.black.withOpacity(dark ? .25 : .1)),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(.4), Colors.transparent],
      ),
    ),
  );
}

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
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.2)),
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, required this.dark});
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(.08)
                : Colors.black.withOpacity(.06),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(dark ? .2 : .15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: child,
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.validator,
    required this.dark,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.w600,
        color: dark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(
          color: dark ? Colors.white70 : Colors.black54,
        ),
        floatingLabelStyle: GoogleFonts.cairo(
          color: dark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: dark ? Colors.white70 : Colors.black54),
        filled: true,
        fillColor: (dark ? Colors.white : Colors.black).withOpacity(.08),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: dark ? Colors.white : Colors.black,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: (dark ? Colors.white : Colors.black).withOpacity(.15),
          ),
        ),
        errorStyle: GoogleFonts.cairo(color: const Color(0xFFFF8A80)),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.loading,
    required this.onTap,
    required this.dark,
  });

  final bool loading;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Animate(
        effects: const [ScaleEffect(curve: Curves.elasticOut)],
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(.4),
          ),
          child: loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.t('login'),
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BioButton extends StatelessWidget {
  const _BioButton({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('bioSoon')))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (dark ? Colors.white : Colors.black).withOpacity(.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              color: dark ? Colors.white70 : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              context.t('useBiometric'),
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: dark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.15),
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
