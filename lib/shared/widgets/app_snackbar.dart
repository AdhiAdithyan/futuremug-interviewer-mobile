import 'package:flutter/material.dart';

/// One place to show feedback, so every screen looks and behaves the same.
abstract final class AppSnackbar {
  static void showError(BuildContext context, String message) {
    _show(context, message, isError: true);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, isError: false);
  }

  static void _show(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? scheme.error : null,
        ),
      );
  }
}
