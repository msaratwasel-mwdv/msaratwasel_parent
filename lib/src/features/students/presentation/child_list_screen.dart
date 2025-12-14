import 'package:flutter/material.dart';

class ChildListScreen extends StatelessWidget {
  const ChildListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأبناء')),
      body: const Center(child: Text('Child list placeholder')),
    );
  }
}
