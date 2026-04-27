import 'package:flutter_test/flutter_test.dart';

import 'package:bloglyzer/main.dart';

void main() {
  testWidgets('App renders input screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BloglyzerApp());
    expect(find.text('Bloglyzer'), findsOneWidget);
    expect(find.text('분석하기'), findsOneWidget);
  });
}
