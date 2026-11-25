import 'package:flutter/material.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';

/// Full-screen error with a retry button, for screens whose data failed to
/// load. Shows the API message when there is one.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.footer,
  });

  final Object error;
  final VoidCallback onRetry;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOffline = error is NetworkException || error is TimeoutApiException;
    final message = error is ApiException
        ? (error as ApiException).message
        : 'Something went wrong. Please try again.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
            if (footer != null) ...[
              const SizedBox(height: 24),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
