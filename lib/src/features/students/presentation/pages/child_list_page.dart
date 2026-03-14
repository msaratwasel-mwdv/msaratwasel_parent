import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChildListPage extends StatelessWidget {
  const ChildListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final students = controller.students;

    return Scaffold(
      appBar: AppBar(title: const Text('الأبناء')),
      body: students.isEmpty
          ? const Center(child: Text('لا يوجد طلاب مسجلين حالياً'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildStudentItem(context, student);
              },
            ),
    );
  }

  Widget _buildStudentItem(BuildContext context, Student student) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withAlpha(20)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary.withAlpha(15),
          backgroundImage: student.avatarUrl != null && student.avatarUrl!.isNotEmpty
              ? CachedNetworkImageProvider(student.avatarUrl!)
              : null,
          child: student.avatarUrl == null || student.avatarUrl!.isEmpty
              ? Text(
                  student.name.isNotEmpty ? student.name.characters.first : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${student.grade} | ${student.schoolName ?? "-"}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () {
          // TODO: الانتقال لصفحة التفاصيل
        },
      ),
    );
  }
}
