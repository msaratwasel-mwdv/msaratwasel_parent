import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';

class AddChildPage extends StatelessWidget {
  const AddChildPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('addChild'))),
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
