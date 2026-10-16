import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

const mask = '••••••';

/// A user with a 2 000,00 € balance that went down 100,00 € since last month.
FakeBackend backendWithBalance() {
  final backend = FakeBackend();
  backend.transactionsOf('fabio').add({
    'id': 't1',
    'type': 'expense',
    'name': 'Supermarket',
    'amountCents': -10000,
    'date': '${backend.today.substring(0, 7)}-01',
  });
  return backend;
}

Future<FakeBackend> openDashboard(WidgetTester tester, {Map<String, Object> stored = const {}}) async {
  final backend = backendWithBalance();
  await pumpApp(tester, backend: backend, loggedIn: true, stored: stored);
  backend.setBalance('fabio', 200000);
  await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('the eye hides the balance everywhere, and shows it again', (tester) async {
    await openDashboard(tester);
    expect(find.text('€2,000.00'), findsOneWidget);
    expect(find.textContaining('since the end of last month'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide balance'));
    await tester.pumpAndSettle();

    expect(find.text('€2,000.00'), findsNothing);
    expect(find.text(mask), findsOneWidget);
    expect(find.textContaining('since the end of last month'), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('balance_hidden'), isTrue);

    // Hidden in the drawer too, and it can be shown from there.
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text(mask), findsWidgets);
    await tester.tap(find.byTooltip('Show balance').last);
    await tester.pumpAndSettle();
    expect(find.text('€2,000.00'), findsWidgets);
    expect(find.text(mask), findsNothing);
  });

  testWidgets('stays hidden after the app restarts', (tester) async {
    await openDashboard(tester, stored: {'balance_hidden': true});

    expect(find.text(mask), findsOneWidget);
    expect(find.text('€2,000.00'), findsNothing);
    expect(find.byTooltip('Show balance'), findsOneWidget);
  });

  testWidgets('hides it on the Profile screen too', (tester) async {
    await openDashboard(tester, stored: {'balance_hidden': true});
    await openDrawerAndTap(tester, 'Profile');

    expect(find.text(mask), findsOneWidget);
    expect(find.text('€2,000.00'), findsNothing);
  });
}
