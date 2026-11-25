import 'package:flutter/material.dart';
import 'package:futuremug_interviewer/core/constants/asset_paths.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

/// Shown while the stored session is read. It has no timer of its own: the
/// router leaves this screen as soon as the auth state is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                AssetPaths.appIcon,
                width: 112,
                height: 112,
                semanticLabel: 'Futuremug',
              ),
            ),
            const SizedBox(height: 24),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: 'future'),
                  TextSpan(
                    text: 'mug',
                    style: TextStyle(color: FuturemugColors.blueAccent),
                  ),
                ],
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'INTERVIEWER',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
