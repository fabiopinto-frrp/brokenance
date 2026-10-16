import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

Future<FakeBackend> openSubscriptions(WidgetTester tester) async {
  final backend = FakeBackend();
  await pumpApp(tester, backend: backend, loggedIn: true);
  await openDrawerAndTap(tester, 'Subscriptions');
  return backend;
}

Future<void> pick(WidgetTester tester, String field, String option) async {
  await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, field));
  await tester.pumpAndSettle();
  // The open menu only builds the options near the selected one: go to its top, then scroll down
  // to the wanted one.
  final menu = find
      .ancestor(of: find.byType(DropdownMenuItem<int>).last, matching: find.byType(Scrollable))
      .first;
  await tester.drag(menu, const Offset(0, 3000));
  await tester.pumpAndSettle();
  final item = find.descendant(of: menu, matching: find.text(option));
  await tester.scrollUntilVisible(item, 48, scrollable: menu);
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> openAdd(WidgetTester tester, {required String name, required String amount}) async {
  await tester.tap(find.widgetWithText(FloatingActionButton, 'Add'));
  await tester.pumpAndSettle();
  await fillField(tester, 'Name', name);
  await fillField(tester, 'Amount', amount);
}

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('adds a monthly subscription', (tester) async {
    final backend = await openSubscriptions(tester);
    expect(find.text('No subscriptions yet'), findsOneWidget);

    await openAdd(tester, name: 'Gym', amount: '35');
    await pick(tester, 'Day of the month', '8');
    await save(tester);

    expect(find.text('Gym'), findsOneWidget);
    expect(find.textContaining('Every month on day 8'), findsOneWidget);
    expect(find.textContaining('Next charge:'), findsOneWidget);
    expect(find.text('Monthly: €35.00   ·   Yearly: €0.00'), findsOneWidget);
    expect(backend.subscriptionsOf('fabio').single, containsPair('billingDay', 8));
  });

  testWidgets('adds a yearly subscription with its month', (tester) async {
    final backend = await openSubscriptions(tester);

    await openAdd(tester, name: 'Car insurance', amount: '240');
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    await pick(tester, 'Day of the month', '10');
    await pick(tester, 'Month', 'March');
    await save(tester);

    expect(find.textContaining('Every year on 10 March'), findsOneWidget);
    expect(find.text('€20.00'), findsOneWidget); // 240 / 12 per month on average
    expect(backend.subscriptionsOf('fabio').single, containsPair('billingMonth', 3));
  });

  testWidgets('does not accept a day the month never has', (tester) async {
    final backend = await openSubscriptions(tester);

    await openAdd(tester, name: 'Odd', amount: '10');
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    await pick(tester, 'Day of the month', '30');
    await pick(tester, 'Month', 'February');
    await save(tester);

    expect(find.text("That month doesn't have this day"), findsOneWidget);
    expect(backend.subscriptionsOf('fabio'), isEmpty);
  });

  testWidgets('can be paused', (tester) async {
    final backend = await openSubscriptions(tester);
    await openAdd(tester, name: 'Netflix', amount: '15,99');
    await save(tester);

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await save(tester);

    expect(find.textContaining('Paused'), findsOneWidget);
    expect(backend.subscriptionsOf('fabio').single['active'], isFalse);
    expect(find.text('Monthly: €0.00   ·   Yearly: €0.00'), findsOneWidget);
  });
}
