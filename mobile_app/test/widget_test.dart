import 'package:flutter_test/flutter_test.dart';
import 'package:mizan_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BaytAlQanoonApp());
    // Initial splash frame
    expect(find.text('بـيـت الـقـانـون'), findsOneWidget);
    // Advance past splash transition
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 800));
  });
}
