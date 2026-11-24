import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

class CountryCode {
  final String name;
  final String code;
  final String flag;

  const CountryCode({required this.name, required this.code, required this.flag});
}

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const List<CountryCode> _countryCodes = [
    CountryCode(name: 'India', code: '+91', flag: '🇮🇳'),
    CountryCode(name: 'United States', code: '+1', flag: '🇺🇸'),
    CountryCode(name: 'United Kingdom', code: '+44', flag: '🇬🇧'),
    CountryCode(name: 'United Arab Emirates', code: '+971', flag: '🇦🇪'),
    CountryCode(name: 'Singapore', code: '+65', flag: '🇸🇬'),
    CountryCode(name: 'Australia', code: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Germany', code: '+49', flag: '🇩🇪'),
  ];

  CountryCode _selectedCountry = _countryCodes[0];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      final fullPhoneNumber = '${_selectedCountry.code}${_phoneController.text.trim()}';
      context.push('/otp-verification', extra: fullPhoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuturemugColors.surfacePureWhite,
      appBar: AppBar(
        title: const Text('Phone Verification'),
        actions: [
          TextButton(
            onPressed: () => context.go('/sign-in'),
            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: FuturemugColors.navySubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      color: FuturemugColors.navyPrimary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Step 1: Enter Phone Number',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: FuturemugColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your country code and enter a mobile number to receive a 6-digit OTP.',
                  style: TextStyle(
                    fontSize: 14,
                    color: FuturemugColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Country Code & Phone Number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FuturemugColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: FuturemugColors.surfacePureWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FuturemugColors.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CountryCode>(
                          value: _selectedCountry,
                          items: _countryCodes.map((country) {
                            return DropdownMenuItem<CountryCode>(
                              value: country,
                              child: Row(
                                children: [
                                  Text(country.flag, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(country.code, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCountry = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '98765 43210',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (value.trim().length < 7) {
                            return 'Enter valid phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _onSendOtp,
                  child: const Text('Receive OTP'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
