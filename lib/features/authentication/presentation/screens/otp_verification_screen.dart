import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/core/router/app_routes.dart';
import 'package:futuremug_interviewer/features/authentication/application/sign_up_flow_controller.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/widgets/otp_code_field.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';
import 'package:futuremug_interviewer/shared/widgets/section_card.dart';
import 'package:futuremug_interviewer/shared/widgets/step_progress_header.dart';

/// Sign-up step 2 of 3: enter the SMS code, verified by the API.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _maxAttempts = 5;

  final _codeController = TextEditingController();
  Timer? _timer;
  int _resendIn = 0;
  int _failedAttempts = 0;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    final challenge = ref.read(signUpFlowProvider).challenge;
    _resendIn = challenge?.resendAfterSeconds ?? 30;
    _timer = _createCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer(int seconds) {
    _timer?.cancel();
    setState(() => _resendIn = seconds);
    _timer = _createCountdown();
  }

  Timer _createCountdown() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text;
    if (code.length != _otpLength || _isVerifying) return;
    if (_failedAttempts >= _maxAttempts) {
      AppSnackbar.showError(context, 'Too many attempts. Request a new code.');
      return;
    }
    setState(() => _isVerifying = true);
    try {
      await ref.read(signUpFlowProvider.notifier).verifyOtp(code);
      if (mounted) context.go(AppRoutes.signUpCredentials);
    } on ApiException catch (e) {
      if (!mounted) return;
      _failedAttempts++;
      _codeController.clear();
      AppSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(signUpFlowProvider.notifier).resendOtp();
      if (!mounted) return;
      _failedAttempts = 0;
      _codeController.clear();
      final challenge = ref.read(signUpFlowProvider).challenge;
      _startResendTimer(challenge?.resendAfterSeconds ?? 30);
      AppSnackbar.showInfo(context, 'A new code has been sent.');
    } on ApiException catch (e) {
      if (mounted) AppSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = ref.watch(signUpFlowProvider);
    final destination =
        flow.challenge?.maskedDestination ?? flow.displayPhone;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgressHeader(currentStep: 2, totalSteps: 3),
              const SizedBox(height: 20),
              SectionCard(
                icon: Icons.sms_outlined,
                eyebrow: 'Verification code',
                title: 'Enter the 6-digit code',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'We sent a code to '),
                          TextSpan(
                            text: destination,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.signUpPhone),
                        child: const Text('Change number'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OtpCodeField(
                      controller: _codeController,
                      length: _otpLength,
                      enabled: !_isVerifying,
                      onCompleted: (_) => _verify(),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _resendIn > 0
                          ? Text(
                              'Resend code in ${_resendIn}s',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : TextButton.icon(
                              onPressed: _isResending ? null : _resend,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Resend code'),
                            ),
                    ),
                    const SizedBox(height: 20),
                    ListenableBuilder(
                      listenable: _codeController,
                      builder: (context, _) => PrimaryButton(
                        label: 'Verify',
                        isLoading: _isVerifying,
                        onPressed: _codeController.text.length == _otpLength
                            ? _verify
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
