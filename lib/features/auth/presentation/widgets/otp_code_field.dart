import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A numeric one-time-code field configured for the native Android and iOS
/// autofill surfaces.
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    this.controller,
    this.focusNode,
    this.length = 6,
    this.autofocus = true,
    this.enabled = true,
    this.labelText = 'Verification code',
    this.onChanged,
    this.onCompleted,
  }) : assert(length > 0);

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int length;
  final bool autofocus;
  final bool enabled;
  final String labelText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        autofillHints: const [AutofillHints.oneTimeCode],
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        enableSuggestions: false,
        autocorrect: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        maxLength: length,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ],
        decoration: InputDecoration(
          labelText: labelText,
          hintText: List.filled(length, '0').join(),
          counterText: '',
          semanticCounterText: '$length digit verification code',
        ),
        onChanged: (value) {
          onChanged?.call(value);
          if (value.length != length) return;

          TextInput.finishAutofillContext(shouldSave: false);
          onCompleted?.call(value);
        },
      ),
    );
  }
}
