import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:provider/provider.dart';

class LanguageSelectorPage extends StatelessWidget {
  const LanguageSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();

    return Scaffold(
      appBar: AppBar(title: const Text('اختر اللغة | Choose Language')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 20,
                children: [
                  _LangButton(
                    label: 'العربية',
                    onPressed: () {
                      controller.updateLocale(const Locale('ar'));
                      Navigator.pop(context);
                    },
                  ),
                  _LangButton(
                    label: 'English',
                    onPressed: () {
                      controller.updateLocale(const Locale('en'));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _LangButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
