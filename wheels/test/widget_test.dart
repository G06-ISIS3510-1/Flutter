import 'package:flutter_test/flutter_test.dart';
import 'package:wheels/app/wheels_app.dart';

void main() {
  testWidgets('Wheels app renders login placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const WheelsApp());
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}
