import 'package:flutter/material.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';
import 'package:futuremug_interviewer/features/authentication/domain/credential_rules.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  static const _labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
  static const _colors = [
    FuturemugColors.borderSubtle,
    FuturemugColors.dangerRose,
    FuturemugColors.warningAmber,
    FuturemugColors.blueAccent,
    FuturemugColors.successEmerald,
  ];

  @override
  Widget build(BuildContext context) {
    final score = CredentialRules.strength(password);
    if (score == 0) return const SizedBox.shrink();
    final color = _colors[score];

    return Semantics(
      label: 'Password strength: ${_labels[score]}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              for (var i = 1; i <= 4; i++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= score ? color : FuturemugColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 4) const SizedBox(width: 4),
              ],
              const SizedBox(width: 10),
              Text(
                _labels[score],
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
