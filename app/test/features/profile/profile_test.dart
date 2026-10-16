import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

Future<FakeBackend> openProfile(WidgetTester tester, {FakeBackend? backend, String language = 'en'}) async {
  final server = backend ?? FakeBackend();
  await pumpApp(tester, backend: server, loggedIn: true, language: language);
  await openDrawerAndTap(tester, language == 'pt' ? 'Perfil' : 'Profile');
  return server;
}

Future<void> typeAndSave(WidgetTester tester, String label, String text) async {
  await fillField(tester, label, text);
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
}

Future<void> setBalance(WidgetTester tester, String text) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Set balance'));
  await tester.pumpAndSettle();
  await typeAndSave(tester, 'Current balance', text);
}

void main() {
  group('balance', () {
    testWidgets('asks for the balance the first time, then shows it here and in the drawer', (tester) async {
      final backend = await openProfile(tester);

      expect(find.text("What's your balance today?"), findsOneWidget);
      await setBalance(tester, '2500,50');

      expect(backend.moneyOf('fabio'), (income: 0, netWorth: 250050, netWorthSet: true));
      expect(find.text('€2,500.50'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(find.text('€2,500.50'), findsNWidgets(2));
    });

    testWidgets('can be edited later, and can be negative', (tester) async {
      final backend = await openProfile(tester);
      await setBalance(tester, '100');

      await tester.tap(find.text('€100.00'));
      await tester.pumpAndSettle();
      expect(find.text('The difference is saved in your history as an adjustment.'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '100.00'), findsOneWidget);

      await typeAndSave(tester, 'Current balance', '-20.5');
      expect(backend.moneyOf('fabio').netWorth, -2050);
      expect(find.text('-€20.50'), findsOneWidget);
    });

    testWidgets('rejects what is not an amount', (tester) async {
      final backend = await openProfile(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Set balance'));
      await tester.pumpAndSettle();

      await typeAndSave(tester, 'Current balance', '12,345,6');
      expect(find.text('Enter a valid amount, like 12.50'), findsOneWidget);

      await typeAndSave(tester, 'Current balance', '99999999');
      expect(find.text('The amount is too large'), findsOneWidget);
      expect(backend.moneyOf('fabio').netWorthSet, isFalse);
    });

    testWidgets('uses the Portuguese format', (tester) async {
      final backend = await openProfile(tester, language: 'pt');
      await tester.tap(find.widgetWithText(FilledButton, 'Definir saldo'));
      await tester.pumpAndSettle();
      await fillField(tester, 'Saldo atual', '1.234,56');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(backend.moneyOf('fabio').netWorth, 123456);
      expect(find.text('1\u00A0234,56\u00A0€'), findsOneWidget);
    });
  });

  testWidgets('sets the monthly income', (tester) async {
    final backend = await openProfile(tester);
    expect(find.text('Not set'), findsOneWidget);

    await tester.tap(find.text('Monthly income'));
    await tester.pumpAndSettle();
    await typeAndSave(tester, 'Amount', '900');

    expect(backend.moneyOf('fabio').income, 90000);
    expect(find.text('€900.00'), findsOneWidget);
    expect(find.text('Added on the 1st of every month'), findsOneWidget);
  });

  testWidgets('edits the name, also in the drawer', (tester) async {
    await openProfile(tester);

    await tester.tap(find.text('Fábio'));
    await tester.pumpAndSettle();
    await fillField(tester, 'First name', 'João');
    await typeAndSave(tester, 'Last name', 'Conceição');

    expect(find.text('João'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('João Conceição'), findsOneWidget);
  });

  group('change password', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Change password'));
      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester, {
      required String current,
      required String fresh,
      String? confirm,
    }) async {
      await fillField(tester, 'Current password', current);
      await fillField(tester, 'New password', fresh);
      await fillField(tester, 'Confirm new password', confirm ?? fresh);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('changes it and stays logged in', (tester) async {
      await openProfile(tester);
      await openSheet(tester);

      await fill(tester, current: 'correct horse battery', fresh: 'a brand new passphrase');

      expect(find.text('Password changed'), findsOneWidget);
      // The new tokens were saved: the app still works.
      await tester.drag(find.byType(ListView).first, const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('Log in to continue.'), findsNothing);
    });

    testWidgets('says when the current password is wrong, and keeps the sheet open', (tester) async {
      await openProfile(tester);
      await openSheet(tester);

      await fill(tester, current: 'wrong password', fresh: 'a brand new passphrase');

      expect(find.text('The current password is wrong.'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Current password'), findsOneWidget);
    });

    testWidgets('checks the new password before sending', (tester) async {
      await openProfile(tester);
      await openSheet(tester);

      await fill(tester, current: 'x', fresh: 'short', confirm: 'other');

      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text("The passwords don't match"), findsOneWidget);
    });
  });

  testWidgets('shows an error with "Try again" when the profile cannot load', (tester) async {
    final backend = FakeBackend()..failProfile = true;
    await openProfile(tester, backend: backend);

    expect(find.text('Something went wrong. Try again.'), findsOneWidget);

    backend.failProfile = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text("What's your balance today?"), findsOneWidget);
  });
}
