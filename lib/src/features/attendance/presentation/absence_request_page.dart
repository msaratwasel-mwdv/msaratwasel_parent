import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';

class AbsenceRequestPage extends StatefulWidget {
  const AbsenceRequestPage({super.key});

  @override
  State<AbsenceRequestPage> createState() => _AbsenceRequestPageState();
}

class _AbsenceRequestPageState extends State<AbsenceRequestPage> {
  int _selectedTab = 0; // 0: Request, 1: Log
  int selectedStudent = 1;
  int selectedAbsenceType = 0;
  DateTime? selectedDate;

  // Extended mock data for "Whole Year"
  final _fullLog = [
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'type': 0, // Full Absence
      'status': 'approved',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'type': -1, // Present
      'status': 'present',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'type': -1, // Present
      'status': 'present',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'type': 1, // Return only
      'status': 'pending',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 12)),
      'type': -1, // Present
      'status': 'present',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 25)),
      'type': 2, // Morning only
      'status': 'rejected',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 60)),
      'type': 0, // Full
      'status': 'approved',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text(
            context.t('attendance'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontFamily: 'Cairo', // Ensure font consistency
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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
                  // Student Selector (Moved here as requested)
                  Text(
                    context.t('chooseStudent'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _studentSelector(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Tabs
                  _modernTabs(textTheme, isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Content
                  if (_selectedTab == 0)
                    _buildRequestForm(textTheme, isDark)
                  else
                    _buildAbsenceLog(textTheme, isDark),
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

  Widget _buildRequestForm(TextTheme textTheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          // Assuming "Type of Absence" key or just localized hardcoded for now
          // Adding key 'absenceType' or similar would be better, but 'attendance' context implies it.
          // Let's use localized labels.
          // "نوع الغياب" -> context.t('absenceType') ?? 'نوع الغياب' (if missing)
          // I will use hardcoded map here for now or add key.
          'نوع الغياب', // TODO: Add key 'absenceType'
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        _absenceTypeRow(textTheme, isDark),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.t('selectDate'),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        _modernDatePicker(textTheme, isDark),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.t('absenceReason'),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        _modernReasonField(textTheme, isDark),
        const SizedBox(height: AppSpacing.xxl),
        _submitButton(textTheme),
      ],
    );
  }

  Widget _buildAbsenceLog(TextTheme textTheme, bool isDark) {
    int presentCount = 0;
    int absentCount = 0;

    for (var item in _fullLog) {
      if (item['type'] == -1) {
        presentCount++;
      } else {
        absentCount++;
      }
    }

    if (_fullLog.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            isDark ? 'لا يوجد سجل غياب' : 'No attendance history',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary Table
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "$presentCount",
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "أيام الحضور", // TODO: Localize context.t('presentDays')
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.border,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "$absentCount",
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "أيام الغياب", // TODO: Localize context.t('absentDays')
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        ListView.separated(
          shrinkWrap:
              true, // Needed since it's inside a CustomScrollView -> SliverToBoxAdapter -> Column
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _fullLog.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final item = _fullLog[index];
            final date = item['date'] as DateTime;
            final type = item['type'] as int;
            final status = item['status'] as String;

            String typeLabel;
            IconData icon;
            Color color;

            if (type == -1) {
              typeLabel = 'حاضر';
              icon = Icons.check_circle;
              color = Colors.green;
            } else if (type == 0) {
              typeLabel = context.t('absenceFull');
              icon = Icons.block;
              color = Colors.redAccent;
            } else if (type == 1) {
              typeLabel = context.t('absenceIn');
              icon = Icons.arrow_forward;
              color = Colors.orange;
            } else {
              typeLabel = context.t('absenceOut');
              icon = Icons.arrow_back;
              color = Colors.orange;
            }

            final isPresent = type == -1;

            return Container(
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
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${date.year}-${date.month}-${date.day}",
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPresent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'approved'
                            ? Colors.green.withValues(alpha: 0.1)
                            : status == 'rejected'
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'approved'
                            ? 'مقبول'
                            : status == 'rejected'
                            ? 'مرفوض'
                            : 'قيد المراجعة',
                        style: textTheme.labelSmall?.copyWith(
                          color: status == 'approved'
                              ? Colors.green
                              : status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _modernTabs(TextTheme textTheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab(textTheme, context.t('requestAbsence'), 0, isDark),
          _tab(textTheme, context.t('absenceLog'), 1, isDark),
        ],
      ),
    );
  }

  Widget _tab(TextTheme textTheme, String title, int index, bool isDark) {
    final bool active = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
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
        hintText: "مثال: موعد طبي...",
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
