import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class SkillManagementScreen extends ConsumerWidget {
  const SkillManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FuturemugColors.canvasAlabaster,
      appBar: AppBar(
        title: const Text('Evaluator Competency Tracks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              title: Text('Mobile Application Engineering (Flutter / iOS / Android)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Seniority: Staff Architect • 8+ Years Experience'),
              trailing: Icon(Icons.verified, color: FuturemugColors.successEmerald),
            ),
          ),
        ],
      ),
    );
  }
}
