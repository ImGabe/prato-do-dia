import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prato_do_dia/pages/home_page.dart';

void main() {
  testWidgets('invalid API URL shows validation error', (tester) async {
    await tester.pumpWidget(const TestApp(child: HomePage()));

    await tester.tap(find.byTooltip('API Settings'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '192.168.1.15:42917');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid URL with http:// or https://'),
      findsOneWidget,
    );
    expect(find.text('API Settings'), findsOneWidget);
  });

  testWidgets('valid API URL closes settings dialog', (tester) async {
    await tester.pumpWidget(const TestApp(child: HomePage()));

    await tester.tap(find.byTooltip('API Settings'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'http://192.168.1.15:42917',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('API Settings'), findsNothing);
  });
}

class TestApp extends StatelessWidget {
  const TestApp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }
}
