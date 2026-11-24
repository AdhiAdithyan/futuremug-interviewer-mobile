import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class InterviewFeedbackScreen extends ConsumerWidget {
  const InterviewFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FuturemugColors.canvasAlabaster,
      appBar: AppBar(
        title: const Text('Scorecard Evaluation & Rubric'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Candidate Evaluation Rubric',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FuturemugColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. System Design Architecture & Scalability', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  const Text('Rate candidate proficiency from 1 (Novice) to 5 (Expert Master).', style: TextStyle(color: FuturemugColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  Slider(
                    value: 4.0,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: '4 - Strong',
                    onChanged: (val) {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
