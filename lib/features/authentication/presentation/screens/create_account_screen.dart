import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';
import 'package:futuremug_interviewer/features/authentication/application/sign_up_flow_controller.dart';
import 'package:futuremug_interviewer/features/authentication/domain/credential_rules.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/widgets/password_strength_meter.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';
import 'package:futuremug_interviewer/shared/widgets/section_card.dart';
import 'package:futuremug_interviewer/shared/widgets/step_progress_header.dart';

/// Sign-up step 3 of 3: choose a username and password. On success the user
/// is signed in and the router opens the profile setup.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _usernameServerError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    setState(() => _usernameServerError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = ref.read(signUpFlowProvider).verificationToken;
    if (token == null) return; // The router sends the user back to step 1.

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            verificationToken: token,
            username: _usernameController.text,
            password: _passwordController.text,
          );
      // The router redirects to profile setup. The sign-up state is kept so
      // the profile form can prefill the verified phone number; it is reset
      // on sign-out.
    } on ConflictException catch (e) {
      if (!mounted) return;
      setState(() => _usernameServerError = e.message);
      _formKey.currentState?.validate();
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
      appBar: AppBar(title: const Text('Create your account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgressHeader(currentStep: 3, totalSteps: 3),
              const SizedBox(height: 20),
              SectionCard(
                icon: Icons.person_add_alt_1_rounded,
                eyebrow: 'Sign-in details',
                title: 'Choose a username and password',
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newUsername],
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          onChanged: (_) {
                            if (_usernameServerError != null) {
                              setState(() => _usernameServerError = null);
                            }
                          },
                          validator: (value) =>
                              _usernameServerError ??
                              CredentialRules.username(value),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            helperText:
                                'At least 8 characters, with a letter and a number',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: CredentialRules.password,
                        ),
                        PasswordStrengthMeter(
                          password: _passwordController.text,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmController,
                          enabled: !_isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onCreate(),
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (value) => CredentialRules.confirmPassword(
                            value,
                            _passwordController.text,
                          ),
                        ),
                        const SizedBox(height: 28),
                        PrimaryButton(
                          label: 'Create account',
                          isLoading: _isSubmitting,
                          onPressed: _onCreate,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Next, you will set up your interviewer profile.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
