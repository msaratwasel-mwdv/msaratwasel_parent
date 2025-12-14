import 'package:flutter/material.dart';

class ChildDetailPage extends StatelessWidget {
  const ChildDetailPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطالب')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الطالب: $studentId'),
            const SizedBox(height: 8),
            const Text('الصف | رقم الحافلة | معلومات السائق/المشرفة'),
            const SizedBox(height: 12),
            const Text('TODO: ربط سجل الرحلات'),
          ],
        ),
      ),
    );
  }
}
