import 'package:flutter_test/flutter_test.dart';
import 'package:vaibhav_academic/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VaibhavAcademicApp());
    expect(find.byType(VaibhavAcademicApp), findsOneWidget);
  });
}
