import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/shared/validation/validators.dart';
import 'package:futuremug_interviewer/shared/widgets/async_submit.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';

/// Common IANA time zones offered in the picker, with friendly labels.
const Map<String, String> kTimezones = {
  'Asia/Kolkata': 'India (UTC+5:30)',
  'Asia/Dubai': 'UAE (UTC+4)',
  'Asia/Singapore': 'Singapore (UTC+8)',
  'Europe/London': 'United Kingdom',
  'Europe/Berlin': 'Central Europe',
  'America/New_York': 'US Eastern',
  'America/Chicago': 'US Central',
  'America/Denver': 'US Mountain',
  'America/Los_Angeles': 'US Pacific',
  'Australia/Sydney': 'Australia Eastern',
  'UTC': 'UTC',
};

/// Best guess of the device's zone from its current UTC offset.
String guessTimezone() {
  final minutes = DateTime.now().timeZoneOffset.inMinutes;
  return switch (minutes) {
    330 => 'Asia/Kolkata',
    240 => 'Asia/Dubai',
    480 => 'Asia/Singapore',
    0 => 'Europe/London',
    60 || 120 => 'Europe/Berlin',
    -240 || -300 => 'America/New_York',
    -360 => 'America/Chicago',
    -420 => 'America/Denver',
    -480 => 'America/Los_Angeles',
    600 || 660 => 'Australia/Sydney',
    _ => 'UTC',
  };
}

/// Personal details form, used by profile setup (step 1) and edit profile.
class PersonalDetailsForm extends StatefulWidget {
  const PersonalDetailsForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
    this.defaultPhone,
  });

  final PersonalDetails? initial;

  /// Prefills the phone when [initial] has none (e.g. the verified number).
  final String? defaultPhone;
  final String submitLabel;
  final Future<void> Function(PersonalDetails details) onSubmit;

  @override
  State<PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late String _timezone;
  DateTime? _dateOfBirth;
  bool _isSubmitting = false;

  static final DateFormat _dobFormat = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.fullName);
    _email = TextEditingController(text: initial?.email);
    _phone = TextEditingController(
      text: (initial?.phone.isNotEmpty ?? false)
          ? initial!.phone
          : widget.defaultPhone,
    );
    _city = TextEditingController(text: initial?.city);
    _country = TextEditingController(text: initial?.country);
    _timezone = initial?.timezone ?? guessTimezone();
    _dateOfBirth = initial?.dateOfBirth;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(1940),
      lastDate: latest,
      helpText: 'Date of birth',
    );
    if (picked != null && mounted) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final details = PersonalDetails(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
      timezone: _timezone,
      dateOfBirth: _dateOfBirth,
      city: _city.text.trim(),
      country: _country.text.trim(),
    );
    await runWithErrorSnackbar(context, () => widget.onSubmit(details));
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final zones = {
      ...kTimezones,
      if (!kTimezones.containsKey(_timezone)) _timezone: _timezone,
    };

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) => Validators.required(v, 'your full name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              hintText: '+919876543210',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: Validators.phoneE164,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _isSubmitting ? null : _pickDateOfBirth,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of birth (optional)',
                prefixIcon: Icon(Icons.cake_outlined),
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                _dateOfBirth == null ? 'Select' : _dobFormat.format(_dateOfBirth!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _city,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) => Validators.required(v, 'your city'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _country,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Country'),
                  validator: (v) => Validators.required(v, 'your country'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _timezone,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Time zone',
              prefixIcon: Icon(Icons.schedule_outlined),
            ),
            items: [
              for (final entry in zones.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _isSubmitting
                ? null
                : (value) {
                    if (value != null) setState(() => _timezone = value);
                  },
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: widget.submitLabel,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
