import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:futuremug_interviewer/main.dart';

void main() {
  testWidgets('Futuremug Interviewer App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FuturemugInterviewerApp());

    // Verify app initializes successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
