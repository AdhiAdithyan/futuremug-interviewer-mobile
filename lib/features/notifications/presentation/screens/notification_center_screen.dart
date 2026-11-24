import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FuturemugColors.canvasAlabaster,
      appBar: AppBar(
        title: const Text('Notification Center'),
      ),
      body: const Center(
        child: Text('Interview Dispatch & System Alerts Feed'),
      ),
    );
  }
}
