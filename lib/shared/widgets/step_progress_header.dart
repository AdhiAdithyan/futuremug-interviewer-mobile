import 'package:flutter/material.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_app_theme.dart';

/// "STEP 2 OF 3" pill with a progress bar, used at the top of multi-step flows.
class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  }) : assert(currentStep >= 1 && currentStep <= totalSteps);

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = currentStep / totalSteps;
    final percent = (progress * 100).round();

    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(FuturemugAppTheme.radiusMd),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Text(
                'STEP $currentStep OF $totalSteps',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.secondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
