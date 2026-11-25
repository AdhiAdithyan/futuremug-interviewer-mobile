import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/core/router/app_routes.dart';
import 'package:futuremug_interviewer/features/authentication/application/sign_up_flow_controller.dart';
import 'package:futuremug_interviewer/features/authentication/domain/country_code.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/brand_app_bar.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';
import 'package:futuremug_interviewer/shared/widgets/section_card.dart';
import 'package:futuremug_interviewer/shared/widgets/step_progress_header.dart';

/// Sign-up step 1 of 3: mobile number with country code → OTP is sent.
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  CountryCode _country = CountryCode.all.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(signUpFlowProvider.notifier).sendOtp(
            countryCode: _country.dialCode,
            phoneNumber: _phoneController.text,
          );
      if (mounted) unawaited(context.push(AppRoutes.signUpOtp));
    } on ApiException catch (e) {
      if (mounted) AppSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: BrandAppBar(
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Sign in'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgressHeader(currentStep: 1, totalSteps: 3),
              const SizedBox(height: 20),
              SectionCard(
                icon: Icons.verified_user_outlined,
                eyebrow: 'Create your account',
                title: 'Verify your mobile number',
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "We'll send a 6-digit code by SMS to confirm it's you.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 116,
                            child: DropdownButtonFormField<CountryCode>(
                              initialValue: _country,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Code',
                              ),
                              items: [
                                for (final c in CountryCode.all)
                                  DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      '${c.flag} ${c.dialCode}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _isSubmitting
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      setState(() => _country = value);
                                      // Re-check the number against the new rules.
                                      if (_phoneController.text.isNotEmpty) {
                                        _formKey.currentState?.validate();
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.telephoneNumberNational,
                              ],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  _country.maxLength,
                                ),
                              ],
                              onFieldSubmitted: (_) => _onSendOtp(),
                              decoration: InputDecoration(
                                labelText: 'Mobile number',
                                hintText: _country.example,
                              ),
                              validator: (value) =>
                                  _country.validate(value ?? ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'Send code',
                        isLoading: _isSubmitting,
                        onPressed: _onSendOtp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
