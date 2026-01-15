import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_user/src/features/attendance/presentation/widgets/child_selector.dart';
import 'package:google_fonts/google_fonts.dart';

class AbsenceRequestPage extends StatefulWidget {
  const AbsenceRequestPage({super.key});

  @override
  State<AbsenceRequestPage> createState() => _AbsenceRequestPageState();
}

class _AbsenceRequestPageState extends State<AbsenceRequestPage> {
  // Mock Data
  final List<AttendanceChild> _children = [
    AttendanceChild(id: '1', name: 'أحمد', grade: 'الخامس - أ'),
    AttendanceChild(id: '2', name: 'سارة', grade: 'الثاني - ب'),
  ];

  late AttendanceChild _selectedChild;
  int _selectedAbsenceType = 0;
  DateTime? _selectedDate;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedChild = _children.first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onChildSelected(AttendanceChild child) {
    setState(() {
      _selectedChild = child;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  ChildSelector(
                    children: _children,
                    selectedChild: _selectedChild,
                    onChildSelected: _onChildSelected,
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
          onPressed: () {
            // TODO: Implement submission logic
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم إرسال الطلب بنجاح',
                  style: GoogleFonts.cairo(),
                ),
              ),
            );
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
