import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/features/auth/presentation/widgets/otp_code_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onCompleted,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: OtpCodeField(
          controller: controller,
          autofocus: false,
          onChanged: onChanged,
          onCompleted: onCompleted,
        ),
      ),
    );
  }

  testWidgets('configures native one-time-code autofill', (tester) async {
    await tester.pumpWidget(buildSubject());

    final editableText = tester.widget<EditableText>(find.byType(EditableText));

    expect(editableText.autofillHints, contains(AutofillHints.oneTimeCode));
    expect(editableText.keyboardType, TextInputType.number);
    expect(editableText.enableSuggestions, isFalse);
    expect(editableText.autocorrect, isFalse);
  });

  testWidgets('keeps six digits and reports completion', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    String? completedCode;

    await tester.pumpWidget(
      buildSubject(
        controller: controller,
        onChanged: changes.add,
        onCompleted: (code) => completedCode = code,
      ),
    );

    await tester.enterText(find.byType(TextFormField), '12a34567');
    await tester.pump();

    expect(controller.text, '123456');
    expect(changes.last, '123456');
    expect(completedCode, '123456');
  });

  testWidgets('does not complete before all digits are entered', (
    tester,
  ) async {
    String? completedCode;

    await tester.pumpWidget(
      buildSubject(onCompleted: (code) => completedCode = code),
    );

    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.pump();

    expect(completedCode, isNull);
  });
}
