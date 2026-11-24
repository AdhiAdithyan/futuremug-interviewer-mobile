import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class InterviewSchedulesScreen extends ConsumerWidget {
  const InterviewSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: FuturemugColors.canvasAlabaster,
        appBar: AppBar(
          title: const Text('Interview Schedules'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Upcoming Interview Roster')),
            Center(child: Text('Completed Scorecard History')),
            Center(child: Text('Cancelled & Rescheduled Log')),
          ],
        ),
      ),
    );
  }
}
