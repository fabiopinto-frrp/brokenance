import 'package:brokenance/app.dart';
import 'package:brokenance/core/network/api_client.dart';
import 'package:brokenance/core/storage/app_preferences.dart';
import 'package:brokenance/core/storage/session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, {Map<String, Object> stored = const {}}) async {
  SharedPreferences.setMockInitialValues(stored);
  final preferences = await AppPreferences.load();
  final apiClient = ApiClient(baseUrl: 'http://api.test', session: MemorySessionStorage());
  await tester.pumpWidget(BrokenanceApp(preferences: preferences, apiClient: apiClient));
  await tester.pumpAndSettle();
}

Future<void> openDrawerAndTap(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.menu_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  // Tests have no internet: use the default font instead of downloading Inter.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('opens on the dashboard', (tester) async {
    await pumpApp(tester, stored: {'locale': 'en'});

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('the drawer lists every section and navigates', (tester) async {
    await pumpApp(tester, stored: {'locale': 'en'});
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    for (final label in [
      'Dashboard', 'Profile', 'Subscriptions', 'Expenses', 'Outings & holidays',
      'Leisure', 'Savings', 'Goals', 'Settings',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Expenses'), findsOneWidget);
  });

  testWidgets('changing the language translates the app and is remembered', (tester) async {
    await pumpApp(tester, stored: {'locale': 'en'});
    await openDrawerAndTap(tester, 'Settings');

    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Definições'), findsOneWidget);
    expect(find.text('IDIOMA'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('locale'), 'pt');

    await openDrawerAndTap(tester, 'Despesas');
    expect(find.text('Em breve'), findsOneWidget);
  });

  testWidgets('switches to dark mode and keeps the page', (tester) async {
    await pumpApp(tester, stored: {'locale': 'en'});
    await openDrawerAndTap(tester, 'Settings');

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });
}
