import 'package:flutter/material.dart';

class AbsenceHistoryPage extends StatelessWidget {
  const AbsenceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الغياب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [Text('TODO: عرض تاريخ الغياب والحالة')],
      ),
    );
  }
}
