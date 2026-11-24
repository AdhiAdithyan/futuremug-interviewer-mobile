import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class EarningsDashboardScreen extends ConsumerWidget {
  const EarningsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FuturemugColors.canvasAlabaster,
      appBar: AppBar(
        title: const Text('Escrow Earnings & Accruals'),
      ),
      body: const Center(
        child: Text('Read-Only Escrow Ledger & Payout History'),
      ),
    );
  }
}
