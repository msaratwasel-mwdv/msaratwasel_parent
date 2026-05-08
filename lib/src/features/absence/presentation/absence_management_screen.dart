import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';

class AbsenceManagementScreen extends StatelessWidget {
  const AbsenceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('requestAbsence'))),
      body: const Center(child: Text('Absence management placeholder')),
    );
  }
}
