import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';

/// Unified Change password page.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final app = AppScope.of(context);
      final response = await app.dio.post(
        'auth/change-password',
        data: {
          'current_password': _currentCtrl.text,
          'new_password': _newCtrl.text,
          'new_password_confirmation': _confirmCtrl.text,
        },
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final msg = response.data['message'] ?? context.t('passwordUpdatedSuccess');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.cairo(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMsg = context.t('fieldRequired');
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['errors'] != null) {
            final errors = data['errors'] as Map;
            errorMsg = errors.values
                .expand((v) => v is List ? v : [v])
                .join('\n');
          } else if (data['message'] != null) {
            errorMsg = data['message'];
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.cairo(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          AppSliverHeader(
            title: context.t('changePassword'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon with animation
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).scale(delay: 100.ms),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    Text(
                      context.t('signInToContinue'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    
                    const SizedBox(height: AppSpacing.xxl),

                    // Fields with animations
                    _buildPasswordField(
                      controller: _currentCtrl,
                      label: context.t('currentPassword'),
                      icon: Icons.lock_outline_rounded,
                      show: _showCurrent,
                      onToggle: () => setState(() => _showCurrent = !_showCurrent),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return context.t('fieldRequired');
                        }
                        return null;
                      },
                      isDark: isDark,
                    ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                    
                    const SizedBox(height: AppSpacing.lg),

                    _buildPasswordField(
                      controller: _newCtrl,
                      label: context.t('newPassword'),
                      icon: Icons.lock_rounded,
                      show: _showNew,
                      onToggle: () => setState(() => _showNew = !_showNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return context.t('fieldRequired');
                        }
                        if (v.length < 6) {
                          return context.t('passwordLengthError');
                        }
                        return null;
                      },
                      isDark: isDark,
                    ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                    
                    const SizedBox(height: AppSpacing.lg),

                    _buildPasswordField(
                      controller: _confirmCtrl,
                      label: context.t('confirmPassword'),
                      icon: Icons.lock_rounded,
                      show: _showConfirm,
                      onToggle: () => setState(() => _showConfirm = !_showConfirm),
                      validator: (v) {
                        if (v != _newCtrl.text) {
                          return context.t('passwordMismatch');
                        }
                        return null;
                      },
                      isDark: isDark,
                    ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),
                    
                    const SizedBox(height: AppSpacing.xxxl),

                    // Submit Button with animation
                    SizedBox(
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.t('savePassword'),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool show,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark 
          ? Colors.white.withValues(alpha: 0.05) 
          : Colors.grey.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
