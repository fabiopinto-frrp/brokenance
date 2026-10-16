import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

Future<FakeBackend> open(WidgetTester tester, String section) async {
  final backend = FakeBackend();
  await pumpApp(tester, backend: backend, loggedIn: true);
  await openDrawerAndTap(tester, section);
  return backend;
}

Future<void> tapAdd(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FloatingActionButton, 'Add'));
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester, [String label = 'Save']) async {
  await tester.ensureVisible(find.widgetWithText(FilledButton, label));
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

void main() {
  group('savings targets', () {
    testWidgets('the newest target is the current one, the old one goes to the history', (tester) async {
      final backend = await open(tester, 'Savings');
      expect(find.text('No savings target yet'), findsOneWidget);

      await tapAdd(tester);
      await fillField(tester, 'Amount', '200');
      await tapSave(tester);
      expect(find.text('You want to save per month'), findsOneWidget);
      expect(find.text('€200.00'), findsOneWidget);

      // An older one, added with an earlier date, goes straight to the history.
      backend.savingsOf('fabio').add({'id': 'old', 'amountCents': 10000, 'effectiveDate': '2026-01-01'});
      await tester.drag(find.byType(ListView).first, const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.text('€100.00'), findsOneWidget);
      expect(find.text('€200.00'), findsOneWidget);
    });

    testWidgets('never changes the balance', (tester) async {
      final backend = await open(tester, 'Savings');
      await tapAdd(tester);
      await fillField(tester, 'Amount', '300');
      await tapSave(tester);

      expect(backend.moneyOf('fabio').netWorth, 0);
    });
  });

  group('goals', () {
    Future<void> addGoal(WidgetTester tester, {required String target, String? saved}) async {
      await tapAdd(tester);
      await fillField(tester, 'What are you saving for?', 'New laptop');
      await fillField(tester, 'Target amount', target);
      if (saved != null) await fillField(tester, 'Already saved', saved);
      await tapSave(tester);
    }

    testWidgets('shows the progress and what is missing', (tester) async {
      await open(tester, 'Goals');
      expect(find.text('No goals yet'), findsOneWidget);

      await addGoal(tester, target: '1000', saved: '250');

      expect(find.text('New laptop'), findsOneWidget);
      expect(find.text('€250.00 of €1,000.00'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('€750.00 to go'), findsOneWidget);
    });

    testWidgets('"+ Add" adds to the saved amount until it is completed', (tester) async {
      final backend = await open(tester, 'Goals');
      await addGoal(tester, target: '100');

      await tester.tap(find.widgetWithText(TextButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Add to New laptop'), findsOneWidget);
      await fillField(tester, 'Amount', '100');
      await tapSave(tester, 'Add');

      expect(backend.goalsOf('fabio').single['savedCents'], 10000);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('estimates the months with the savings target', (tester) async {
      final backend = FakeBackend();
      await pumpApp(tester, backend: backend, loggedIn: true);
      backend.savingsOf('fabio').add({'id': 's', 'amountCents': 30000, 'effectiveDate': '2026-01-01'});
      await openDrawerAndTap(tester, 'Goals');

      await addGoal(tester, target: '1000', saved: '100');

      expect(find.text('€900.00 to go · About 3 months at your savings target'), findsOneWidget);
    });
  });
}
