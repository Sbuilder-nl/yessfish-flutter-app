import 'package:flutter_test/flutter_test.dart';
import 'package:yessfish/main.dart';

void main() {
  testWidgets('App start smoke test', (tester) async {
    await tester.pumpWidget(const YessFishApp());
    expect(find.byType(YessFishApp), findsOneWidget);
  });
}
