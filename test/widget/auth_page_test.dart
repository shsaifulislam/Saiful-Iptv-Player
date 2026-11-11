import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/features/auth/presentation/auth_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createAuthWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: ProviderScope(
          child: AuthPage(),
        ),
      ),
    );
  }

  testWidgets('renders sign in form with fields and buttons', (tester) async {
    await tester.pumpWidget(createAuthWidget());
    await tester.pumpAndSettle();

    expect(find.text('Sign In to Saiful IPTV'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
    expect(find.text('Sign In'), findsNWidgets(2)); // Segment & Button
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('switches between Sign In and Register modes', (tester) async {
    await tester.pumpWidget(createAuthWidget());
    await tester.pumpAndSettle();

    // Tap 'Register' segment
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3)); // Email, Password, Confirm Password
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('validates required fields on submit', (tester) async {
    await tester.pumpWidget(createAuthWidget());
    await tester.pumpAndSettle();

    // Tap submit button while fields are empty
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
  });

  testWidgets('opens forgot password dialog', (tester) async {
    await tester.pumpWidget(createAuthWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Send recovery email'), findsOneWidget);
  });
}

