import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume_app/screens/login_screen.dart';

void main() {
  testWidgets('LUME app loads Login screen', (WidgetTester tester) async {
    // Build app WITH ROUTES (important)
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Allow UI to settle
    await tester.pumpAndSettle();

    // Verify app title
    expect(find.text('LUME'), findsOneWidget);

    // Verify Login input field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify SEND OTP button exists
    expect(find.text('SEND OTP'), findsOneWidget);

    // Verify Register text exists
    expect(find.textContaining('Register'), findsOneWidget);
  });
}
