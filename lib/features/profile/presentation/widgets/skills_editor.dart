import 'package:flutter/material.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/features/profile/domain/skill_catalog.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/async_submit.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';

/// List of skills with add / edit / remove, used by profile setup (step 3)
/// and edit profile. At least one skill is required.
class SkillsEditor extends StatefulWidget {
  const SkillsEditor({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial = const [],
  });

  final List<SkillEntry> initial;
  final String submitLabel;
  final Future<void> Function(List<SkillEntry> skills) onSubmit;

  @override
  State<SkillsEditor> createState() => _SkillsEditorState();
}

class _SkillsEditorState extends State<SkillsEditor> {
  late List<SkillEntry> _skills;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _skills = [...widget.initial];
  }

  Future<void> _edit({SkillEntry? existing, int? index}) async {
    final result = await showModalBottomSheet<SkillEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SkillSheet(existing: existing),
    );
    if (result == null || !mounted) return;

    final duplicate = _skills.indexWhere(
      (s) => s.name.toLowerCase() == result.name.toLowerCase(),
    );
    if (duplicate != -1 && duplicate != index) {
      AppSnackbar.showError(context, '${result.name} is already in your list.');
      return;
    }
    setState(() {
      if (index == null) {
        _skills = [..._skills, result];
      } else {
        _skills = [..._skills]..[index] = result;
      }
    });
  }

  void _remove(int index) {
    setState(() => _skills = [..._skills]..removeAt(index));
  }

  Future<void> _submit() async {
    if (_skills.isEmpty) {
      AppSnackbar.showError(context, 'Add at least one skill you can interview for.');
      return;
    }
    setState(() => _isSubmitting = true);
    await runWithErrorSnackbar(context, () => widget.onSubmit(_skills));
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byDomain = <String, List<(int, SkillEntry)>>{};
    for (var i = 0; i < _skills.length; i++) {
      byDomain.putIfAbsent(_skills[i].domain, () => []).add((i, _skills[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add the skills you can interview candidates for. You will only '
          'be offered interviews that match them.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_skills.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'No skills yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final entry in byDomain.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              entry.key.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          for (final (index, skill) in entry.value)
            Card(
              child: ListTile(
                title: Text(
                  skill.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${skill.proficiency.label} · '
                  '${_years(skill.yearsExperience)}',
                ),
                onTap: _isSubmitting
                    ? null
                    : () => _edit(existing: skill, index: index),
                trailing: IconButton(
                  tooltip: 'Remove ${skill.name}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _isSubmitting ? null : () => _remove(index),
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : () => _edit(),
          icon: const Icon(Icons.add),
          label: const Text('Add a skill'),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: widget.submitLabel,
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }

  static String _years(double years) {
    final text =
        years == years.roundToDouble() ? years.toInt().toString() : '$years';
    return years == 1 ? '1 year' : '$text years';
  }
}

/// Bottom sheet to add or edit one skill.
class _SkillSheet extends StatefulWidget {
  const _SkillSheet({this.existing});

  final SkillEntry? existing;

  @override
  State<_SkillSheet> createState() => _SkillSheetState();
}

class _SkillSheetState extends State<_SkillSheet> {
  static const _other = 'Other (type it)';

  final _formKey = GlobalKey<FormState>();
  final _customSkill = TextEditingController();
  late String _domain;
  String? _skill;
  late double _years;
  late ProficiencyLevel _level;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _domain = existing?.domain ?? SkillCatalog.domainNames.first;
    if (!SkillCatalog.domains.containsKey(_domain)) {
      _domain = SkillCatalog.domainNames.first;
    }
    if (existing != null) {
      final known = SkillCatalog.skillsFor(_domain).contains(existing.name);
      _skill = known ? existing.name : _other;
      if (!known) _customSkill.text = existing.name;
    }
    _years = (existing?.yearsExperience ?? 3).clamp(0, 30).toDouble();
    _level = existing?.proficiency ?? ProficiencyLevel.advanced;
  }

  @override
  void dispose() {
    _customSkill.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _skill == _other ? _customSkill.text.trim() : _skill!;
    Navigator.of(context).pop(
      SkillEntry(
        skillId: widget.existing?.skillId,
        name: name,
        domain: _domain,
        yearsExperience: _years,
        proficiency: _level,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skills = [...SkillCatalog.skillsFor(_domain), _other];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Add a skill' : 'Edit skill',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _domain,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Domain'),
                items: [
                  for (final d in SkillCatalog.domainNames)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (value) {
                  if (value == null || value == _domain) return;
                  setState(() {
                    _domain = value;
                    _skill = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // Rebuild when the domain changes so the selection resets.
                key: ValueKey(_domain),
                initialValue: _skill,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Skill'),
                items: [
                  for (final s in skills)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (value) => setState(() => _skill = value),
                validator: (value) => value == null ? 'Choose a skill' : null,
              ),
              if (_skill == _other) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customSkill,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Skill name'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 2) return 'Enter the skill name';
                    if (t.length > 60) return 'Keep it under 60 characters';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Experience: ${_years == _years.roundToDouble() ? _years.toInt() : _years} '
                '${_years == 1 ? 'year' : 'years'}',
                style: theme.textTheme.titleSmall,
              ),
              Slider(
                value: _years,
                max: 30,
                divisions: 60,
                label: _years.toString(),
                onChanged: (v) => setState(() => _years = v),
              ),
              const SizedBox(height: 8),
              Text('Proficiency', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ProficiencyLevel>(
                segments: [
                  for (final level in ProficiencyLevel.values)
                    ButtonSegment(value: level, label: Text(level.label)),
                ],
                selected: {_level},
                onSelectionChanged: (selection) =>
                    setState(() => _level = selection.first),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: widget.existing == null ? 'Add skill' : 'Save skill',
                trailingIcon: null,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
