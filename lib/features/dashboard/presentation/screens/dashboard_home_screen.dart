import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FuturemugColors.canvasAlabaster,
      appBar: AppBar(
        title: const Text('Interviewer Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Total Escrow Earnings',
                    style: TextStyle(
                      fontSize: 13,
                      color: FuturemugColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$12,450.00',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: FuturemugColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '+18.4% from last month',
                    style: TextStyle(
                      fontSize: 12,
                      color: FuturemugColors.successEmerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Upcoming Interviews Today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FuturemugColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: FuturemugColors.navySubtle,
                child: Text('DC', style: TextStyle(color: FuturemugColors.navyPrimary, fontWeight: FontWeight.bold)),
              ),
              title: const Text('David Chen - Staff Android Engineer', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('10:00 AM - 11:00 AM (EST) • Live Code Companion'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
