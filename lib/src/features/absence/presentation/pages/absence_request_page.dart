import 'package:flutter/material.dart';

class AbsenceRequestPage extends StatelessWidget {
  const AbsenceRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل غياب')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('اختيار الطلاب وأنواع الغياب'),
            SizedBox(height: 8),
            Text('TODO: إرسال الطلب إلى MARK_ABSENT_API'),
          ],
        ),
      ),
    );
  }
}
