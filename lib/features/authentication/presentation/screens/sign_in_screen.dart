import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FuturemugColors.canvasAlabaster,
      appBar: AppBar(
        title: const Text('Sign In - Futuremug Interviewer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Welcome Back, Evaluator',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: FuturemugColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sign in securely with your corporate credentials or verified email.',
              style: TextStyle(
                fontSize: 14,
                color: FuturemugColors.textSecondary,
              ),
            ),
            SizedBox(height: 32),
            TextField(
              decoration: InputDecoration(
                labelText: 'Enterprise Email',
                hintText: 'evaluator@futuremug.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: '••••••••••••',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: null,
              child: Text('Sign In Securely'),
            ),
          ],
        ),
      ),
    );
  }
}
