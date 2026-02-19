import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:witt_app/app/app.dart';

void main() {
  testWidgets('App renders 5-tab navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WittApp()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Learn'), findsWidgets);
    expect(find.text('Sage'), findsWidgets);
    expect(find.text('Social'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });
}
