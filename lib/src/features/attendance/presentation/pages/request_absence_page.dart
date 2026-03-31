import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';

class RequestAbsencePage extends StatefulWidget {
  const RequestAbsencePage({super.key});

  @override
  State<RequestAbsencePage> createState() => _RequestAbsencePageState();
}

class _RequestAbsencePageState extends State<RequestAbsencePage> {
  String? selectedStudentId;
  int selectedAbsenceType = 0;
  DateTime? selectedDate = DateTime.now();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (selectedStudentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار طالب')),
        );
      }
      return;
    }

    if (selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('selectDate'))),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final controller = AppScope.of(context);
      
      final type = selectedAbsenceType == 0 
          ? AbsenceType.both 
          : selectedAbsenceType == 1 
              ? AbsenceType.morning 
              : AbsenceType.returnOnly;

      final bool success = await controller.submitAbsenceRequest(
        studentIds: [selectedStudentId!],
        type: type,
        date: selectedDate!,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب الغياب بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Ensure UI stays stable, wait before closing
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          AppScope.of(context).moveBack();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إرسال الطلب، الرجاء المحاولة مرة أخرى'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('ABSENCE_SUBMIT_ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Exception') ? 'حدث خطأ غير متوقع' : e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: context.t('requestAbsence'),
            leading: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t('chooseStudent'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _studentSelector(context, textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    context.t('absenceType'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _absenceTypeRow(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    context.t('selectDate'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _modernDatePicker(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    context.t('absenceReason'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _modernReasonField(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xxl),
                  _submitButton(textTheme),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentSelector(BuildContext context, TextTheme textTheme, bool isDark) {
    final students = AppScope.of(context).students;

    if (students.isEmpty) {
      return Center(child: Text(context.t('noStudentsRegistered')));
    }

    // Default to first student if not set
    selectedStudentId ??= students.first.id;

    return Column(
      children: [
        for (var student in students) ...[
          _studentCard(textTheme, student.name, student.id, isDark),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _studentCard(TextTheme textTheme, String name, String id, bool isDark) {
    final bool selected = selectedStudentId == id;

    return InkWell(
      onTap: () => setState(() => selectedStudentId = id),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
          border: selected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: selected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey[100]),
              child: Icon(
                Icons.person_rounded,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.blueGrey),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              name,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? (isDark ? Colors.white : AppColors.primary)
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: isDark ? Colors.white : AppColors.primary,
                size: 26,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _absenceTypeRow(TextTheme textTheme, bool isDark) {
    return Row(
      children: [
        _absenceCard(
          textTheme,
          context.t('absenceFull'),
          Icons.block,
          0,
          isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _absenceCard(
          textTheme,
          context.t('absenceIn'),
          Icons.arrow_forward,
          1,
          isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _absenceCard(
          textTheme,
          context.t('absenceOut'),
          Icons.arrow_back,
          2,
          isDark,
        ),
      ],
    );
  }

  Widget _absenceCard(
    TextTheme textTheme,
    String title,
    IconData icon,
    int type,
    bool isDark,
  ) {
    final bool active = selectedAbsenceType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedAbsenceType = type),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.07)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Theme.of(context).cardColor),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (!active)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
            border: active
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.12),
                  ),
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: active ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: active
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? Colors.white70 : Colors.blueGrey[300]),
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  color: active
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? Colors.white : AppColors.textSecondary),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernDatePicker(TextTheme textTheme, bool isDark) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              selectedDate != null
                  ? "${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}"
                  : context.t('selectDate'),
              style: textTheme.bodyLarge?.copyWith(
                color: selectedDate != null
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernReasonField(TextTheme textTheme, bool isDark) {
    return TextField(
      controller: _reasonController,
      maxLines: 4,
      cursorColor: AppColors.primary,
      style: textTheme.bodyLarge?.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF8F9FA),
        hintText: context.t('reasonHint'),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark
              ? Colors.white60
              : AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _submitButton(TextTheme textTheme) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppColors.brandGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  context.t('sendAbsenceRequest'),
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
