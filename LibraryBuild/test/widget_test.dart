import 'package:flutter_test/flutter_test.dart';

import 'package:library_build/main.dart';

void main() {
  testWidgets('LbMinimalApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const LbMinimalApp());
    await tester.pump();
  });
}
