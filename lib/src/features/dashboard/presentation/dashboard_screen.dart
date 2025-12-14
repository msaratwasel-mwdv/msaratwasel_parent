import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة ولي الأمر')),
      body: const Center(child: Text('Dashboard placeholder')),
    );
  }
}
