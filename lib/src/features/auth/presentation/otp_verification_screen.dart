import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/widgets/frosted_card.dart';
import 'package:msaratwasel_user/src/shared/widgets/primary_button.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/widgets/auth_background.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.controller,
    required this.phoneNumber,
  });

  final AppController controller;
  final String phoneNumber;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto focus on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendTimer = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    if (_otpController.text.length != 4) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // TODO: Navigate to reset password or home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Correct Code'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resendCode() {
    _startTimer();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t('resetLinkSent'))));
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
            icon: Icon(
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
                          Icons.perm_device_information_rounded,
                          size: 64,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ).animate().fadeIn().scale(),

                      const SizedBox(height: 32),

                      FrostedCard(
                        child: Column(
                          children: [
                            Text(
                              context.t('otpVerification'),
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
                              '${context.t('enterOtpSubtitle')}\n${widget.phoneNumber}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Custom 4-digit Input
                            _CustomOtpInput(
                              controller: _otpController,
                              focusNode: _focusNode,
                              isDark: isDark,
                              onChanged: (_) {
                                if (_otpController.text.length == 4) {
                                  _handleVerify();
                                }
                              },
                            ),

                            const SizedBox(height: 32),

                            PrimaryButton(
                              onTap: _handleVerify,
                              text: context.t('verify'),
                              isLoading: _isLoading,
                            ),

                            const SizedBox(height: 24),

                            // Resend Timer
                            if (_resendTimer > 0)
                              Text(
                                '${context.t('resendIn')} 00:${_resendTimer.toString().padLeft(2, '0')}',
                                style: GoogleFonts.cairo(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                  fontSize: 14,
                                ),
                              )
                            else
                              TextButton(
                                onPressed: _resendCode,
                                child: Text(
                                  context.t('resendCode'),
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.dark.accent
                                        : AppColors.accent,
                                  ),
                                ),
                              ),
                          ],
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

class _CustomOtpInput extends StatefulWidget {
  const _CustomOtpInput({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  State<_CustomOtpInput> createState() => _CustomOtpInputState();
}

class _CustomOtpInputState extends State<_CustomOtpInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hidden TextField to capture input
        Opacity(
          opacity: 0,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.number,
            maxLength: 4,
            onChanged: widget.onChanged,
          ),
        ),
        // Visible Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            final text = widget.controller.text;
            final char = index < text.length ? text[index] : '';
            final isActive = index == text.length;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 64,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: .1)
                    : Colors.black.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? (widget.isDark
                            ? AppColors.dark.accent
                            : AppColors.primary)
                      : (widget.isDark ? Colors.white24 : Colors.black12),
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color:
                              (widget.isDark
                                      ? AppColors.dark.accent
                                      : AppColors.primary)
                                  .withValues(alpha: .2),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                char,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Reusing the background
