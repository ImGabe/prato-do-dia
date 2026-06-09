import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prato_do_dia/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const defaultApiBaseUrl = 'http://10.0.2.2:42917';
  const apiBaseUrlPreferenceKey = 'api_base_url';
  const customApiBaseUrl = 'http://192.168.0.42:42917';

  Future<void> pumpHomePage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loads default API URL when no value is stored',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpHomePage(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text(defaultApiBaseUrl), findsOneWidget);
  });

  testWidgets('loads stored API URL value from preferences',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
      {apiBaseUrlPreferenceKey: customApiBaseUrl},
    );
    await pumpHomePage(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text(customApiBaseUrl), findsOneWidget);
  });

  testWidgets('saves API URL updates to preferences', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpHomePage(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), customApiBaseUrl);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(apiBaseUrlPreferenceKey), customApiBaseUrl);
  });
}
