import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

/// A user with this month's spending in three categories (100,00 € in total), a 300,00 € savings
/// target, a goal and a subscription. The fake API's "today" is the device's today.
FakeBackend backendWithData() {
  final backend = FakeBackend();
  final month = backend.today.substring(0, 7);
  backend.transactionsOf('fabio').addAll([
    {'id': 't1', 'type': 'expense', 'name': 'Supermarket', 'amountCents': -6000, 'date': '$month-01'},
    {'id': 't2', 'type': 'outing', 'name': 'Dinner', 'amountCents': -3000, 'date': '$month-01'},
    {'id': 't3', 'type': 'leisure', 'name': 'Cinema', 'amountCents': -1000, 'date': '$month-01'},
  ]);
  backend.savingsOf('fabio').add({'id': 's1', 'amountCents': 30000, 'effectiveDate': '2026-01-01'});
  backend.goalsOf('fabio').add({
    'id': 'g1',
    'name': 'New laptop',
    'targetCents': 100000,
    'savedCents': 25000,
  });
  backend.subscriptionsOf('fabio').add({
    'id': 'sub1',
    'name': 'Gym',
    'amountCents': 3500,
    'period': 'monthly',
    'billingDay': 8,
    'active': true,
  });
  return backend;
}

/// Opens the app on the dashboard with a 2 000,00 € balance already set.
Future<FakeBackend> openWithBalance(WidgetTester tester, [FakeBackend? backend]) async {
  final server = backend ?? backendWithData();
  await pumpApp(tester, backend: server, loggedIn: true);
  server.setBalance('fabio', 200000);
  // Pull to refresh, as the user would.
  await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
  return server;
}

void main() {
  testWidgets('before the balance is set, it points to Profile', (tester) async {
    await pumpApp(tester, loggedIn: true);

    expect(find.text('Your money at a glance'), findsOneWidget);
    await tester.tap(find.text('Open Profile'));
    await tester.pumpAndSettle();
    expect(find.text("What's your balance today?"), findsOneWidget);
  });

  testWidgets('shows the balance, this month and the savings status', (tester) async {
    await openWithBalance(tester);

    expect(find.text('€2,000.00'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('-€100.00'), findsOneWidget); // left this month
    expect(find.text('€400.00 short of your €300.00 savings target'), findsOneWidget);
  });

  testWidgets('splits the spending by category, with names, amounts and shares', (tester) async {
    await openWithBalance(tester);

    await tester.scrollUntilVisible(find.text('Income vs spending'), 200);
    expect(find.text('€60.00'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('€30.00'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget); // no subscription charge this month

    // The stacked bar is really drawn: three segments, 14px tall, widths in proportion.
    final segments = find.descendant(
      of: find.byType(FractionallySizedBox),
      matching: find.byType(ColoredBox),
    );
    final sizes = [for (final element in segments.evaluate()) element.size!];
    expect(sizes, hasLength(3));
    expect(sizes.every((size) => size.height == 14), isTrue);
    expect(sizes[0].width / sizes[2].width, closeTo(6, 0.2)); // 60,00 € vs 10,00 €
  });

  testWidgets('switches the charts to 12 months', (tester) async {
    final backend = await openWithBalance(tester);

    await tester.tap(find.text('12M'));
    await tester.pumpAndSettle();

    expect(backend.api.callsTo('/dashboard/summary').last.queryParameters['months'], 12);
  });

  testWidgets('summarises goals and subscriptions, and opens their screens', (tester) async {
    await openWithBalance(tester);

    await tester.scrollUntilVisible(find.text('1 active · €35.00 per month'), 200);
    expect(find.text('€250.00 of €1,000.00 saved'), findsOneWidget);
    expect(find.text('New laptop'), findsOneWidget);

    await tester.ensureVisible(find.text('1 active · €35.00 per month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 active · €35.00 per month'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Subscriptions'), findsOneWidget);
  });

  testWidgets('says so when nothing was spent this month', (tester) async {
    await openWithBalance(tester, FakeBackend());

    await tester.scrollUntilVisible(find.text('Nothing spent this month yet.'), 200);
    expect(find.text('Nothing spent this month yet.'), findsOneWidget);
  });
}
