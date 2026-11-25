import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_app_theme.dart';

/// Six digit boxes backed by one hidden text field, so paste, backspace and
/// SMS autofill (`AutofillHints.oneTimeCode`) all work like a normal input.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final code = widget.controller.text;

    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      textField: true,
      child: Stack(
        children: [
          // Visible boxes.
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < widget.length; i++)
                  _DigitBox(
                    digit: i < code.length ? code[i] : '',
                    isActive: _focusNode.hasFocus &&
                        (i == code.length ||
                            (i == widget.length - 1 &&
                                code.length == widget.length)),
                    scheme: scheme,
                  ),
              ],
            ),
          ),
          // The real input, transparent, on top of the boxes.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: (value) {
                  if (value.length == widget.length) {
                    widget.onCompleted?.call(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.isActive,
    required this.scheme,
  });

  final String digit;
  final bool isActive;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(FuturemugAppTheme.radiusSm + 2),
        border: Border.all(
          color: isActive ? scheme.secondary : scheme.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Text(
        digit,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
