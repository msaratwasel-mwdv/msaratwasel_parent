import 'package:flutter/material.dart';

class AddChildPage extends StatelessWidget {
  const AddChildPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة ابن')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('نموذج ربط طالب جديد'),
            SizedBox(height: 8),
            Text('TODO: حقول الربط برقم الطالب/المدرسة'),
          ],
        ),
      ),
    );
  }
}
