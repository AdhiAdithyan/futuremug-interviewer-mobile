import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class ProfileOverviewScreen extends ConsumerWidget {
  const ProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FuturemugColors.canvasAlabaster,
      appBar: AppBar(
        title: const Text('Evaluator Profile & Security'),
      ),
      body: const Center(
        child: Text('Evaluator Badges, Trusted Devices & Sign-out Settings'),
      ),
    );
  }
}
