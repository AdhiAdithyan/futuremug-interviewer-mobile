import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/app.dart';
import 'package:futuremug_interviewer/core/config/app_config.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';

import 'helpers/test_app.dart';

/// End-to-end widget tests against the mock API (the default environment).
void main() {
  late AppDatabase database;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    database = AppDatabase.inMemory();
  });

  tearDown(() => database.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...appRootOverrides(database: database),
          appConfigProvider.overrideWithValue(testConfig),
        ],
        child: const FuturemugInterviewerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed-out user lands on the sign-in screen', (tester) async {
    await pumpApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Username or email'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('signing in with valid details opens the dashboard',
      (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username or email'),
      'alex.morgan',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Secret123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Interviewer Dashboard'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    // Dashboard data from the mock API.
    expect(find.text('Hello, Alex'), findsOneWidget);
    expect(find.text('David Chen'), findsOneWidget);
  });

  testWidgets('a wrong password shows the server message', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username or email'),
      'alex.morgan',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect username or password.'), findsOneWidget);
    expect(find.text('Interviewer Dashboard'), findsNothing);
  });

  testWidgets('a user without a profile is sent to profile setup',
      (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username or email'),
      'newuser',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Secret123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Set up your profile'), findsOneWidget);
    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
  });

  testWidgets('empty sign-in form shows validation errors', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your username or email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
