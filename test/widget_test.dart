import 'package:flutter_test/flutter_test.dart';
import 'package:flash_cart/main.dart';

void main() {
  testWidgets('FlashCart app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashCartApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FlashCartApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
