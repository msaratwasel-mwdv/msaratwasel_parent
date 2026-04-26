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
  String _absencePeriod = 'full_day'; // full_day, morning, afternoon
  bool _isSubmitting = false;

  final List<Map<String, String>> _reasons = [
    {'id': 'sick', 'label_ar': 'مرضي', 'label_en': 'Sick'},
    {'id': 'travel', 'label_ar': 'سفر', 'label_en': 'Travel'},
    {'id': 'personal', 'label_ar': 'شخصي', 'label_en': 'Personal'},
  ];

  final List<Map<String, String>> _periods = [
    {'id': 'full_day', 'label_ar': 'يوم كامل', 'label_en': 'Full Day'},
    {'id': 'morning', 'label_ar': 'ذهاب فقط (صباحاً)', 'label_en': 'Morning Only'},
    {'id': 'afternoon', 'label_ar': 'عودة فقط (مساءً)', 'label_en': 'Afternoon Only'},
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final isArabic = controller.locale.languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(context.t('absenceRequest'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Selection
            _buildSectionHeader(context.t('selectStudent')),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: _selectedStudentId,
                  hint: Text(isArabic ? 'اختر الطالب' : 'Select Student'),
                  items: controller.students.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            image: s.avatarUrl != null 
                              ? DecorationImage(image: NetworkImage(s.avatarUrl!), fit: BoxFit.cover)
                              : null,
                          ),
                          child: s.avatarUrl == null 
                            ? Icon(Icons.person, size: 18, color: theme.colorScheme.primary)
                            : null,
                        ),
                        const SizedBox(width: 12),
                        Text(s.name, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedStudentId = val),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Absence Period (New)
            _buildSectionHeader(isArabic ? 'فترة الغياب' : 'Absence Period'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _periods.map((p) => _buildChoiceChip(
                label: isArabic ? p['label_ar']! : p['label_en']!,
                selected: _absencePeriod == p['id'],
                onSelected: (val) => setState(() => _absencePeriod = p['id']!),
              )).toList(),
            ),

            const SizedBox(height: 24),
            
            // Absence Reason
            _buildSectionHeader(isArabic ? 'سبب الغياب' : 'Reason'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: _reasons.map((t) => _buildChoiceChip(
                label: isArabic ? t['label_ar']! : t['label_en']!,
                selected: _absenceType == t['id'],
                onSelected: (val) => setState(() => _absenceType = t['id']!),
              )).toList(),
            ),

            const SizedBox(height: 24),
            
            // Additional Details
            _buildSectionHeader(isArabic ? 'ملاحظات إضافية' : 'Additional Notes'),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: isArabic ? 'اختياري: اكتب التفاصيل هنا...' : 'Optional: Write details here...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedStudentId == null || _isSubmitting)
                    ? null
                    : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        context.t('submit'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool selected, required Function(bool) onSelected}) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      showCheckmark: false,
    );
  }

  Future<void> _handleSubmit() async {
    final controller = context.read<AppController>();
    final isArabic = controller.locale.languageCode == 'ar';

    setState(() => _isSubmitting = true);

    try {
      final response = await controller.submitAbsence(
        studentId: _selectedStudentId!,
        period: _absencePeriod,
        reason: _absenceType,
        note: _reasonController.text,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic ? 'تم إرسال طلب الغياب بنجاح' : 'Absence request sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? (isArabic ? 'فشل إرسال الطلب' : 'Failed to send request')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
