import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/theme/app_spacing.dart';
import 'package:provider/provider.dart';

class ChildDetailPage extends StatelessWidget {
  const ChildDetailPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    final student = controller.students.firstWhere((s) => s.id == studentId);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('studentInfo')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Center(
              child: Hero(
                tag: 'student_avatar_${student.id}',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: student.avatarUrl != null ? NetworkImage(student.avatarUrl!) : null,
                  child: student.avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              student.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '${context.t('studentGrade')}: ${student.grade}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            _InfoSection(
              title: context.t('busInfoTitle'),
              children: [
                _InfoTile(label: context.t('busNumber'), value: student.bus.number),
                _InfoTile(label: context.t('busPlate'), value: student.bus.plate),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoSection(
              title: context.t('busDriver'),
              children: [
                _InfoTile(label: context.t('driverName'), value: student.bus.driver?.name ?? context.t('notAvailable')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
