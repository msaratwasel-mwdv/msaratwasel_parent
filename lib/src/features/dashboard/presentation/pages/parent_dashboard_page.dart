import 'package:flutter/material.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة ولي الأمر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('بطاقات الأبناء و ETA'),
          SizedBox(height: 8),
          Text('TODO: عرض حالات الحافلة والإشعارات السريعة'),
        ],
      ),
    );
  }
}
