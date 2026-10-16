import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('opens on the dashboard when logged in', (tester) async {
    await pumpApp(tester, loggedIn: true);

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('the drawer shows the user and every section, and navigates', (tester) async {
    await pumpApp(tester, loggedIn: true);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Fábio Pinto'), findsOneWidget);
    expect(find.text('@fabio'), findsOneWidget);
    for (final label in [
      'Dashboard',
      'Profile',
      'Subscriptions',
      'Expenses',
      'Outings & holidays',
      'Leisure',
      'Savings',
      'Goals',
      'Settings',
      'Log out',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Expenses'), findsOneWidget);
  });

  testWidgets('changing the language translates the app and is remembered', (tester) async {
    await pumpApp(tester, loggedIn: true);
    await openDrawerAndTap(tester, 'Settings');

    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Definições'), findsOneWidget);
    expect(find.text('IDIOMA'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('locale'), 'pt');

    await openDrawerAndTap(tester, 'Despesas');
    expect(find.text('Ainda sem despesas'), findsOneWidget);
  });

  testWidgets('switches to dark mode and keeps the page', (tester) async {
    await pumpApp(tester, loggedIn: true);
    await openDrawerAndTap(tester, 'Settings');

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });
}
