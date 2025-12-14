import 'package:flutter/material.dart';

class LanguageSelectorPage extends StatelessWidget {
  const LanguageSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر اللغة')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر اللغة المفضلة'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('العربية'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('English'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('TODO: Persist language and refresh app locale.'),
            ],
          ),
        ),
      ),
    );
  }
}
