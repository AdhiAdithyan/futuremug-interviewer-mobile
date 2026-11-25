import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';
import 'package:futuremug_interviewer/features/dashboard/data/dashboard_repository.dart';
import 'package:futuremug_interviewer/features/dashboard/domain/dashboard_summary.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/error_view.dart';

/// Home tab: who you are, today's numbers, and your next interview.
class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Interviewer Dashboard')),
      body: summary.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
          child: _DashboardContent(summary: data),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = summary.stats;
    final money = NumberFormat.simpleCurrency(
      locale: stats.currency == 'INR' ? 'en_IN' : 'en_US',
      name: stats.currency,
      decimalDigits: 0,
    );
    final firstName = summary.fullName.split(' ').first;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (summary.isFromCache) _OfflineBanner(savedAt: summary.savedAt),
        Text(
          firstName.isEmpty ? 'Welcome back' : 'Hello, $firstName',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (summary.tier != null)
              Text(
                summary.tier!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (summary.rating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: FuturemugColors.warningAmber,
                  ),
                  Text(
                    summary.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            if (summary.availabilityLabel.isNotEmpty)
              _StatusPill(label: summary.availabilityLabel),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              icon: Icons.today_outlined,
              label: "Today's interviews",
              value: '${stats.todayInterviews}',
            ),
            _StatCard(
              icon: Icons.pending_actions_outlined,
              label: 'Reports pending',
              value: '${stats.pendingInterviews}',
            ),
            _StatCard(
              icon: Icons.task_alt_outlined,
              label: 'Completed',
              value: '${stats.completedInterviews}',
            ),
            _StatCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total earned',
              value: money.format(stats.totalEarnings),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Next interview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (summary.nextInterview == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No upcoming interviews. Add availability so clients can '
                'book you.',
              ),
            ),
          )
        else
          _NextInterviewCard(interview: summary.nextInterview!),
        if (summary.monthly.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Recent months',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _MonthlyBars(monthly: summary.monthly),
            ),
          ),
        ],
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.savedAt});

  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    final when = savedAt == null
        ? ''
        : ' from ${DateFormat('d MMM, h:mm a').format(savedAt!)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FuturemugColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FuturemugColors.warningBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: FuturemugColors.warningAmber),
          const SizedBox(width: 12),
          Expanded(
            child: Text("You're offline. Showing saved data$when."),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: FuturemugColors.successBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FuturemugColors.successBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF047857),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.secondary),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextInterviewCard extends StatelessWidget {
  const _NextInterviewCard({required this.interview});

  final UpcomingInterview interview;

  Future<void> _join(BuildContext context) async {
    final url = interview.meetingJoinUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      AppSnackbar.showError(context, 'No meeting link yet.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppSnackbar.showError(context, 'Could not open the meeting link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [interview.targetRole, interview.clientCompany]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    final minutes = interview.minutesUntilStart;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    interview.initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interview.candidateName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (interview.timeFormatted != null)
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(interview.timeFormatted!)),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.videocam_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(interview.platformLabel)),
                if (minutes != null && minutes >= 0)
                  Text(
                    minutes < 60
                        ? 'Starts in $minutes min'
                        : 'Starts in ${minutes ~/ 60} h',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _join(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Join meeting'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.monthly});

  final List<MonthlyActivity> monthly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = monthly
        .map((m) => m.interviews)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (final m in monthly)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text(m.month)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxCount == 0 ? 0 : m.interviews / maxCount,
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: Text(
                    '${m.interviews} interviews',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
