import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';

class AbsenceRequestPage extends StatefulWidget {
  const AbsenceRequestPage({super.key});

  @override
  State<AbsenceRequestPage> createState() => _AbsenceRequestPageState();
}

class _AbsenceRequestPageState extends State<AbsenceRequestPage> {
  int selectedStudent = 1;
  int selectedAbsenceType = 0;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    // Removed Directionality as it is handled by MaterialApp
    // Removed Scaffold to avoid nesting inside RootShell's Scaffold

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text(
            "طلب غياب",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          leading: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              width: 0.0,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: viewInsets > 0 ? viewInsets + 12 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _modernTabs(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    "اختر الطالب",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _studentSelector(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    "نوع الغياب",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _absenceTypeRow(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    "تاريخ الغياب",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _modernDatePicker(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    "السبب (اختياري)",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _modernReasonField(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xxl),
                  _submitButton(textTheme),
                  // Add bottom padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernTabs(TextTheme textTheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab(textTheme, "طلب غياب", true, isDark),
          _tab(textTheme, "سجل الغياب", false, isDark),
        ],
      ),
    );
  }

  Widget _tab(TextTheme textTheme, String title, bool active, bool isDark) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppColors.primary.withOpacity(0.18) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: active
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentSelector(TextTheme textTheme, bool isDark) {
    return Column(
      children: [
        _studentCard(textTheme, "أحمد علي", 1, isDark),
        const SizedBox(height: AppSpacing.md),
        _studentCard(textTheme, "فاطمة محمد", 2, isDark),
      ],
    );
  }

  Widget _studentCard(TextTheme textTheme, String name, int id, bool isDark) {
    final bool selected = selectedStudent == id;

    return InkWell(
      onTap: () => setState(() => selectedStudent = id),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
          border: selected
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1.5,
                )
              : Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12),
                ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: selected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withOpacity(0.08)
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
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
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
                        ? Colors.white.withOpacity(0.4)
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
        _absenceCard(textTheme, "غياب كامل", Icons.block, 0, isDark),
        const SizedBox(width: AppSpacing.sm),
        _absenceCard(textTheme, "غياب العودة", Icons.arrow_forward, 1, isDark),
        const SizedBox(width: AppSpacing.sm),
        _absenceCard(textTheme, "غياب الذهاب", Icons.arrow_back, 2, isDark),
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
                ? AppColors.primary.withOpacity(isDark ? 0.22 : 0.07)
                : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Theme.of(context).cardColor),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (!active)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
            border: active
                ? Border.all(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 1.5,
                  )
                : Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.12),
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
                      ? AppColors.primary
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
                      ? AppColors.primary
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
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.grey.withOpacity(0.14),
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
                  : "اختر التاريخ",
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
      maxLines: 4,
      cursorColor: AppColors.primary,
      style: textTheme.bodyLarge?.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF8F9FA),
        hintText: "مثال: موعد طبي...",
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark
              ? Colors.white60
              : AppColors.textSecondary.withOpacity(0.6),
        ),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.12) : Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.12) : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.5),
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
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            "إرسال طلب الغياب",
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
