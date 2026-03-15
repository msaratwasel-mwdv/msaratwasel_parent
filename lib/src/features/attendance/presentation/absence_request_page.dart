import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/widgets/child_selector.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';
import 'package:google_fonts/google_fonts.dart';

class AbsenceRequestPage extends StatefulWidget {
  const AbsenceRequestPage({super.key});

  @override
  State<AbsenceRequestPage> createState() => _AbsenceRequestPageState();
}

class _AbsenceRequestPageState extends State<AbsenceRequestPage> {
  Student? _selectedChild;
  int _selectedAbsenceType = 0;
  DateTime? _selectedDate;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedChild == null) {
      final students = AppScope.of(context).students;
      if (students.isNotEmpty) {
        _selectedChild = students.first;
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onChildSelected(Student child) {
    setState(() {
      _selectedChild = child;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final students = AppScope.of(context).students;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: context.t('requestAbsence'),
            leading: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Child Selector
                  if (students.isNotEmpty)
                    ChildSelector(
                      children: students,
                      selectedChild: _selectedChild,
                      onChildSelected: _onChildSelected,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        AppScope.of(context).locale.languageCode == 'ar'
                            ? 'لا يوجد أبناء مسجلون'
                            : 'No children found',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  // Absence Type
                  Text(
                    context.t('absenceType'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildAbsenceTypeRow(isDark),

                  const SizedBox(height: AppSpacing.xl),

                  // Date Picker
                  Text(
                    context.t('selectDate'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDatePicker(isDark),

                  const SizedBox(height: AppSpacing.xl),

                  // Reason Field
                  Text(
                    context.t('absenceReason'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildReasonField(isDark),

                  const SizedBox(height: AppSpacing.xxl),

                  // Submit Button
                  _buildSubmitButton(context),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceTypeRow(bool isDark) {
    return Row(
      children: [
        _buildAbsenceCard(context.t('absenceFull'), Icons.block, 0, isDark),
        const SizedBox(width: AppSpacing.sm),
        _buildAbsenceCard(
          context.t('absenceIn'),
          Icons.arrow_forward_rounded,
          1,
          isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildAbsenceCard(
          context.t('absenceOut'),
          Icons.arrow_back_rounded,
          2,
          isDark,
        ),
      ],
    );
  }

  Widget _buildAbsenceCard(String title, IconData icon, int type, bool isDark) {
    final bool active = _selectedAbsenceType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedAbsenceType = type),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.3 : 0.1)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? const Color(0xFF1E3A8A)
                  : (isDark ? Colors.white10 : Colors.grey[200]!),
              width: active ? 1.5 : 1,
            ),
            boxShadow: [
              if (!active && !isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active
                    ? const Color(0xFF1E3A8A)
                    : (isDark ? Colors.white70 : Colors.grey[400]),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  color: active
                      ? const Color(0xFF1E3A8A)
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1E3A8A), // Selection color
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF1E3A8A),
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              _selectedDate != null
                  ? "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}"
                  : context.t('selectDate'),
              style: GoogleFonts.cairo(
                color: _selectedDate != null
                    ? (isDark ? Colors.white : AppColors.textPrimary)
                    : (isDark ? Colors.white38 : Colors.grey[400]),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white70 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField(bool isDark) {
    return TextField(
      controller: _reasonController,
      maxLines: 4,
      cursorColor: const Color(0xFF1E3A8A),
      style: GoogleFonts.cairo(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        hintText: context.t('reasonHint'),
        hintStyle: GoogleFonts.cairo(
          color: isDark ? Colors.white38 : Colors.grey[400],
        ),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final controller = AppScope.of(context);
    
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1E3A8A), // Dark Blue
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            if (_selectedChild == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppScope.of(context).locale.languageCode == 'ar'
                        ? 'يرجى اختيار طالب'
                        : 'Please select a student',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              );
              return;
            }

            if (_selectedDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppScope.of(context).locale.languageCode == 'ar'
                        ? 'يرجى اختيار التاريخ'
                        : 'Please select a date',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              );
              return;
            }

            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );

            final success = await controller.submitAbsenceRequest(
              studentIds: [_selectedChild!.id],
              type: _selectedAbsenceType == 0 
                  ? AbsenceType.both 
                  : (_selectedAbsenceType == 1 ? AbsenceType.morning : AbsenceType.returnOnly),
              date: _selectedDate!,
              reason: _reasonController.text,
            );

            // Hide loading
            if (context.mounted) Navigator.pop(context);

            if (success) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppScope.of(context).locale.languageCode == 'ar'
                          ? 'تم إرسال الطلب بنجاح'
                          : 'Request sent successfully',
                      style: GoogleFonts.cairo(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppScope.of(context).locale.languageCode == 'ar'
                          ? 'فشل إرسال الطلب، يرجى المحاولة لاحقاً'
                          : 'Failed to send request, please try again',
                      style: GoogleFonts.cairo(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            context.t('sendAbsenceRequest'),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
