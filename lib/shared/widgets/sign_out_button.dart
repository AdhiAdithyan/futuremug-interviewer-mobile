import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';

/// Asks for confirmation, then signs out. Local drafts stay on the device.
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Sign out'),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text(
              'You will need your username and password to sign in again. '
              'Unsent report drafts stay on this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
        if (confirmed ?? false) {
          await ref.read(authControllerProvider.notifier).signOut();
        }
      },
    );
  }
}
