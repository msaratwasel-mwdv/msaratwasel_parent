import 'package:flutter/material.dart';

class LanguageSelectorScreen extends StatelessWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار اللغة')),
      body: const Center(child: Text('Language selector placeholder')),
    );
  }
}
