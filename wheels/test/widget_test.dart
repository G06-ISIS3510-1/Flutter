import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/app/wheels_app.dart';

void main() {
  testWidgets('Wheels app renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WheelsApp());
    await tester.pumpAndSettle();

    expect(find.text('Wheels'), findsOneWidget);
    expect(find.text('Continue with University Email'), findsOneWidget);
  });
}
