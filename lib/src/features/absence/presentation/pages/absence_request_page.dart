import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:provider/provider.dart';

class AbsenceRequestPage extends StatefulWidget {
  const AbsenceRequestPage({super.key});

  @override
  State<AbsenceRequestPage> createState() => _AbsenceRequestPageState();
}

class _AbsenceRequestPageState extends State<AbsenceRequestPage> {
  String? _selectedStudentId;
  String _absenceType = 'sick';
  final _reasonController = TextEditingController();

  final List<Map<String, String>> _types = [
    {'id': 'sick', 'label_ar': 'مرضي', 'label_en': 'Sick'},
    {'id': 'travel', 'label_ar': 'سفر', 'label_en': 'Travel'},
    {'id': 'personal', 'label_ar': 'شخصي', 'label_en': 'Personal'},
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final isArabic = controller.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('absenceRequest')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('selectStudent'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _selectedStudentId,
              items: controller.students.map((s) => DropdownMenuItem(
                value: s.id,
                child: Row(
                  children: [
                    if (s.avatarUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, left: 8.0),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(s.avatarUrl!),
                        ),
                      ),
                    Text(s.name),
                  ],
                ),
              )).toList(),
              onChanged: (val) => setState(() => _selectedStudentId = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.t('absenceType'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final isSelected = _absenceType == t['id'];
                return ChoiceChip(
                  label: Text(isArabic ? t['label_ar']! : t['label_en']!),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _absenceType = t['id']!),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.t('reason'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isArabic ? 'اكتب السبب هنا...' : 'Write the reason here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedStudentId == null
                    ? null
                    : () async {
                        final success = await controller.submitAbsence(
                          studentId: _selectedStudentId!,
                          type: _absenceType,
                          reason: _reasonController.text,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? (isArabic ? 'تم بنجاح' : 'Success') : (isArabic ? 'فشل إرسال الطلب' : 'Failed'))),
                          );
                          if (success) Navigator.pop(context);
                        }
                      },
                child: Text(context.t('submit')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
