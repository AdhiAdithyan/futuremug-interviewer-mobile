import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class AvailabilityCalendarScreen extends ConsumerWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FuturemugColors.canvasAlabaster,
      appBar: AppBar(
        title: const Text('Availability & Calendar Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: const Center(
        child: Text('Weekly Availability Slot Matrix & Time-off Planner'),
      ),
    );
  }
}
