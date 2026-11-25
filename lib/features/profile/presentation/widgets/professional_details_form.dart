import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/shared/validation/validators.dart';
import 'package:futuremug_interviewer/shared/widgets/async_submit.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';

/// Professional details form, used by profile setup (step 2) and edit profile.
class ProfessionalDetailsForm extends StatefulWidget {
  const ProfessionalDetailsForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
  });

  final ProfessionalDetails? initial;
  final String submitLabel;
  final Future<void> Function(ProfessionalDetails details) onSubmit;

  @override
  State<ProfessionalDetailsForm> createState() =>
      _ProfessionalDetailsFormState();
}

class _ProfessionalDetailsFormState extends State<ProfessionalDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qualification;
  late final TextEditingController _years;
  late final TextEditingController _company;
  late final TextEditingController _designation;
  late final TextEditingController _linkedIn;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _qualification = TextEditingController(text: initial?.highestQualification);
    _years = TextEditingController(
      text: initial == null ? null : _formatYears(initial.yearsOfTotalExperience),
    );
    _company = TextEditingController(text: initial?.currentCompany);
    _designation = TextEditingController(text: initial?.currentDesignation);
    _linkedIn = TextEditingController(text: initial?.linkedInUrl);
  }

  @override
  void dispose() {
    _qualification.dispose();
    _years.dispose();
    _company.dispose();
    _designation.dispose();
    _linkedIn.dispose();
    super.dispose();
  }

  static String _formatYears(double years) =>
      years == years.roundToDouble() ? years.toInt().toString() : '$years';

  String? _validateLinkedIn(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    if (uri == null || !uri.hasScheme || !uri.host.contains('linkedin.com')) {
      return 'Enter a LinkedIn link, e.g. https://www.linkedin.com/in/you';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final details = ProfessionalDetails(
      highestQualification: _qualification.text.trim(),
      yearsOfTotalExperience: double.parse(_years.text.trim()),
      currentCompany: _company.text.trim(),
      currentDesignation: _designation.text.trim(),
      linkedInUrl: _linkedIn.text.trim(),
    );
    await runWithErrorSnackbar(context, () => widget.onSubmit(details));
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _qualification,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Highest qualification',
              hintText: 'e.g. B.Tech in Computer Science',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            validator: (v) => Validators.required(v, 'your qualification'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _years,
            enabled: !_isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d?)?')),
            ],
            decoration: const InputDecoration(
              labelText: 'Total experience (years)',
              prefixIcon: Icon(Icons.timeline_outlined),
            ),
            validator: (v) => Validators.number(
              v,
              fieldName: 'your total experience',
              min: 0,
              max: 50,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _company,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Current company',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (v) => Validators.required(v, 'your current company'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _designation,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Current designation',
              hintText: 'e.g. Senior Software Engineer',
              prefixIcon: Icon(Icons.work_outline),
            ),
            validator: (v) => Validators.required(v, 'your designation'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _linkedIn,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'LinkedIn profile (optional)',
              prefixIcon: Icon(Icons.link),
            ),
            validator: _validateLinkedIn,
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
