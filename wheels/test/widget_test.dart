import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('login entry screen renders expected actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Wheels'), findsOneWidget);
    expect(find.text('Continue with University Email'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
