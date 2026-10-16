import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

Future<FakeBackend> openScreen(WidgetTester tester, String section) async {
  final backend = FakeBackend();
  await pumpApp(tester, backend: backend, loggedIn: true);
  await openDrawerAndTap(tester, section);
  return backend;
}

Future<void> addItem(
  WidgetTester tester, {
  required String name,
  required String amount,
  String? note,
}) async {
  await tester.tap(find.widgetWithText(FloatingActionButton, 'Add'));
  await tester.pumpAndSettle();
  await fillField(tester, 'Name', name);
  await fillField(tester, 'Amount', amount);
  if (note != null) await fillField(tester, 'Note (optional)', note);
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
}

/// Lets the "Undo" time pass, and the delete request finish. The 4 seconds start once the
/// message has finished sliding in.
Future<void> waitForUndoToExpire(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Future<void> swipeAway(WidgetTester tester, String name) async {
  await tester.drag(find.text(name), const Offset(-600, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts empty, then adds an expense that lowers the balance', (tester) async {
    final backend = await openScreen(tester, 'Expenses');
    expect(find.text('No expenses yet'), findsOneWidget);

    await addItem(tester, name: 'Supermarket', amount: '42,50', note: 'Weekly');

    expect(find.text('Supermarket'), findsOneWidget);
    expect(find.text('€42.50'), findsNWidgets(2)); // the row and "Spent this month"
    expect(find.textContaining('Weekly'), findsOneWidget);
    expect(backend.transactionsOf('fabio').single, containsPair('type', 'expense'));
    expect(backend.moneyOf('fabio').netWorth, -4250);
  });

  testWidgets('each screen keeps its own kind', (tester) async {
    final backend = await openScreen(tester, 'Outings & holidays');
    await addItem(tester, name: 'Porto', amount: '120');
    await openDrawerAndTap(tester, 'Leisure');

    expect(find.text('No leisure yet'), findsOneWidget);
    expect(backend.transactionsOf('fabio').single['type'], 'outing');
  });

  testWidgets('edits an item', (tester) async {
    final backend = await openScreen(tester, 'Expenses');
    await addItem(tester, name: 'Supermarket', amount: '42,50');

    await tester.tap(find.text('Supermarket'));
    await tester.pumpAndSettle();
    expect(find.text('Edit expense'), findsOneWidget);
    await fillField(tester, 'Amount', '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('€10.00'), findsNWidgets(2));
    expect(backend.transactionsOf('fabio').single['amountCents'], -1000);
  });

  testWidgets('checks the fields before saving', (tester) async {
    final backend = await openScreen(tester, 'Expenses');
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add'));
    await tester.pumpAndSettle();
    await fillField(tester, 'Amount', '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Enter a valid amount, like 12.50'), findsOneWidget);
    expect(backend.transactionsOf('fabio'), isEmpty);
  });

  group('delete', () {
    testWidgets('swipe hides it, and Undo brings it back without deleting', (tester) async {
      final backend = await openScreen(tester, 'Expenses');
      await addItem(tester, name: 'Supermarket', amount: '42,50');

      await swipeAway(tester, 'Supermarket');
      expect(find.text('Supermarket'), findsNothing);
      expect(find.text('Deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Supermarket'), findsOneWidget);
      expect(backend.transactionsOf('fabio'), hasLength(1));
    });

    testWidgets('without Undo it is deleted and the money comes back', (tester) async {
      final backend = await openScreen(tester, 'Expenses');
      await addItem(tester, name: 'Supermarket', amount: '42,50');

      await swipeAway(tester, 'Supermarket');
      await waitForUndoToExpire(tester);

      expect(backend.transactionsOf('fabio'), isEmpty);
      expect(backend.moneyOf('fabio').netWorth, 0);
      expect(find.text('No expenses yet'), findsOneWidget);
    });

    testWidgets('can also be deleted from the edit sheet', (tester) async {
      final backend = await openScreen(tester, 'Expenses');
      await addItem(tester, name: 'Supermarket', amount: '42,50');

      await tester.tap(find.text('Supermarket'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Delete'));
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await waitForUndoToExpire(tester);

      expect(backend.transactionsOf('fabio'), isEmpty);
    });
  });
}
