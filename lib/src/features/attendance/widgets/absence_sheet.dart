import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:msaratwasel_user/src/shared/utils/labels.dart';

Future<void> showAbsenceSheet(BuildContext context) async {
  final controller = AppScope.of(context);
  final noteController = TextEditingController();
  AttendanceDirection direction = AttendanceDirection.outbound;
  DateTime selectedDate = DateTime.now();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final lang = controller.locale.languageCode;

      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.t('markAbsence'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.t('selectDate'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 5),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (result != null) {
                      setState(() => selectedDate = result);
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    '${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.t('attendance'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<AttendanceDirection>(
                  segments: [
                    ButtonSegment(
                      value: AttendanceDirection.outbound,
                      icon: const Icon(Icons.wb_sunny_rounded),
                      label: Text(
                        _directionLabel(AttendanceDirection.outbound, lang),
                      ),
                    ),
                    ButtonSegment(
                      value: AttendanceDirection.inbound,
                      icon: const Icon(Icons.nightlight_rounded),
                      label: Text(
                        _directionLabel(AttendanceDirection.inbound, lang),
                      ),
                    ),
                    ButtonSegment(
                      value: AttendanceDirection.fullDay,
                      icon: const Icon(Icons.all_inclusive_rounded),
                      label: Text(
                        _directionLabel(AttendanceDirection.fullDay, lang),
                      ),
                    ),
                  ],
                  selected: {direction},
                  onSelectionChanged: (values) =>
                      setState(() => direction = values.first),
                  style: ButtonStyle(
                    side: WidgetStateProperty.all(
                      const BorderSide(color: AppColors.border),
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      AppColors.textPrimary,
                    ),
                    overlayColor: WidgetStateProperty.all(
                      AppColors.primary.withAlpha(20),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: context.t('absenceNote'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () {
                    controller.addAbsence(
                      direction: direction,
                      date: selectedDate,
                      note: noteController.text.isEmpty
                          ? null
                          : noteController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(context.t('createRequest')),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  noteController.dispose();
}

String _directionLabel(AttendanceDirection direction, String lang) {
  return Labels.attendanceDirection(direction, arabic: lang == 'ar');
}
