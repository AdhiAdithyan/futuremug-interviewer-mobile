import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/core/router/app_routes.dart';
import 'package:futuremug_interviewer/features/authentication/data/auth_repository.dart';
import 'package:futuremug_interviewer/features/authentication/domain/credential_rules.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/widgets/otp_code_field.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/widgets/password_strength_meter.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';
import 'package:futuremug_interviewer/shared/widgets/section_card.dart';
import 'package:futuremug_interviewer/shared/widgets/step_progress_header.dart';

/// Password reset in two steps on one screen:
/// 1. email → `POST /auth/password/forgot` sends a code;
/// 2. code + new password → `POST /auth/password/reset`.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _recoverySessionId;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    // On "Send a new code" the email form is no longer shown; the email in
    // the controller was already validated.
    final isResend = _recoverySessionId != null;
    if (!isResend && !(_emailFormKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final sessionId = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _recoverySessionId = sessionId);
      if (isResend) {
        _codeController.clear();
        AppSnackbar.showInfo(context, 'A new code has been sent.');
      }
    } on ApiException catch (e) {
      if (mounted) AppSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final sessionId = _recoverySessionId;
    if (sessionId == null) return;
    if (_codeController.text.length != 6) {
      AppSnackbar.showError(context, 'Enter the 6-digit code we sent you.');
      return;
    }
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            recoverySessionId: sessionId,
            verificationCode: _codeController.text,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      AppSnackbar.showInfo(
        context,
        'Password changed. Sign in with your new password.',
      );
      context.go(AppRoutes.login);
    } on ApiException catch (e) {
      if (mounted) AppSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeSent = _recoverySessionId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StepProgressHeader(currentStep: codeSent ? 2 : 1, totalSteps: 2),
              const SizedBox(height: 20),
              if (!codeSent) _buildEmailStep() else _buildResetStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.mark_email_unread_outlined,
      eyebrow: 'Forgot password',
      title: 'Find your account',
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Enter your account email. We'll send a code to your "
              'registered mobile number and email.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _requestCode(),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Send code',
              isLoading: _isSubmitting,
              onPressed: _requestCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetStep() {
    return SectionCard(
      icon: Icons.lock_reset_rounded,
      eyebrow: 'Check your messages',
      title: 'Set a new password',
      child: Form(
        key: _resetFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OtpCodeField(controller: _codeController, enabled: !_isSubmitting),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              enabled: !_isSubmitting,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: CredentialRules.password,
            ),
            PasswordStrengthMeter(password: _passwordController.text),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              enabled: !_isSubmitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _resetPassword(),
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) => CredentialRules.confirmPassword(
                value,
                _passwordController.text,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Reset password',
              isLoading: _isSubmitting,
              onPressed: _resetPassword,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSubmitting ? null : _requestCode,
              child: const Text('Send a new code'),
            ),
          ],
        ),
      ),
    );
  }
}
