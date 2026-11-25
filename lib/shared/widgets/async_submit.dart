import 'package:flutter/material.dart';
import 'package:futuremug_interviewer/core/files/document_picker.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';

/// Runs [action], showing known errors as a snackbar. Returns `true` on
/// success. Unknown errors are rethrown so they reach the error logger.
Future<bool> runWithErrorSnackbar(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) AppSnackbar.showError(context, e.message);
  } on DocumentPickException catch (e) {
    if (context.mounted) AppSnackbar.showError(context, e.message);
  }
  return false;
}
