import 'package:flutter/material.dart';

class BusTrackingPage extends StatelessWidget {
  const BusTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الحافلة')),
      body: const Center(
        child: Text('TODO: Google Maps + Polyline + ETA + BottomSheet'),
      ),
    );
  }
}
