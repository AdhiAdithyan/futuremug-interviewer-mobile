import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/core/router/app_routes.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';
import 'package:futuremug_interviewer/features/authentication/domain/auth_state.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/brand_app_bar.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';
import 'package:futuremug_interviewer/shared/widgets/section_card.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.prefilledUsername});

  final String? prefilledUsername;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.prefilledUsername);

    // Show why the user was signed out (e.g. expired session), once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authControllerProvider);
      if (mounted && auth is Unauthenticated && auth.reason != null) {
        AppSnackbar.showInfo(context, auth.reason!);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(
            username: _usernameController.text,
            password: _passwordController.text,
          );
      // The router redirects to the dashboard or profile setup.
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
      appBar: const BrandAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    icon: Icons.login_rounded,
                    eyebrow: 'Welcome back',
                    title: 'Sign in',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Username or email',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Enter your username or email'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _onSignIn(),
                          decoration: InputDecoration(
                            labelText: 'Password',
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
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Enter your password'
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => context.push(AppRoutes.forgotPassword),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: 'Sign in',
                          isLoading: _isSubmitting,
                          onPressed: _onSignIn,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to Futuremug?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => context.push(AppRoutes.signUpPhone),
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
