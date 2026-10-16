import 'package:brokenance/core/storage/session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

Future<void> logIn(WidgetTester tester, {required String username, required String password}) async {
  await fillField(tester, 'Username', username);
  await fillField(tester, 'Password', password);
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pumpAndSettle();
}

Future<void> fillRegisterForm(
  WidgetTester tester, {
  String firstName = 'Ana',
  String lastName = 'Conceição',
  String username = 'ana',
  String password = 'a long passphrase',
  String? confirm,
}) async {
  await fillField(tester, 'First name', firstName);
  await fillField(tester, 'Last name', lastName);
  await fillField(tester, 'Username', username);
  await fillField(tester, 'Password', password);
  await fillField(tester, 'Confirm password', confirm ?? password);
}

Future<void> openRegister(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Create account'));
  await tester.pumpAndSettle();
}

Future<void> submitRegister(WidgetTester tester) async {
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
  await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
  await tester.pumpAndSettle();
}

void main() {
  group('start-up', () {
    testWidgets('without a saved session it shows the login screen', (tester) async {
      await pumpApp(tester);

      expect(find.text('Log in to continue.'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
    });

    testWidgets('with a saved session it opens the app directly', (tester) async {
      await pumpApp(tester, loggedIn: true);

      expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    });

    testWidgets('a saved session that already ended goes to the login screen', (tester) async {
      final backend = FakeBackend();
      final session = MemorySessionStorage();
      backend.seedUser();
      backend.expireAllSessions();
      await session.save(const Session(accessToken: 'old', refreshToken: 'old'));

      await pumpApp(tester, backend: backend, session: session);

      expect(find.text('Log in to continue.'), findsOneWidget);
      expect(await session.read(), isNull);
    });

    testWidgets('offline with a saved session it stays logged in', (tester) async {
      await pumpApp(tester, backend: FakeBackend(offline: true), loggedIn: true);

      expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    });
  });

  group('login', () {
    testWidgets('logs in and opens the dashboard', (tester) async {
      final backend = FakeBackend()..seedUser();
      final session = await pumpApp(tester, backend: backend);

      await logIn(tester, username: 'FABIO', password: 'correct horse battery');

      expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
      expect(await session.read(), isNotNull);
    });

    testWidgets('shows a clear error for a wrong password, and clears it when typing', (tester) async {
      await pumpApp(tester, backend: FakeBackend()..seedUser());

      await logIn(tester, username: 'fabio', password: 'wrong password');
      expect(find.text('Wrong username or password.'), findsOneWidget);

      await fillField(tester, 'Password', 'something else');
      await tester.pump();
      expect(find.text('Wrong username or password.'), findsNothing);
    });

    testWidgets('asks for both fields', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('says when the server cannot be reached', (tester) async {
      await pumpApp(tester, backend: FakeBackend(offline: true));

      await logIn(tester, username: 'fabio', password: 'whatever');

      expect(find.text("Can't reach the server. Check your connection."), findsOneWidget);
    });

    testWidgets('the password can be shown and hidden', (tester) async {
      await pumpApp(tester);
      bool obscured() => tester.widget<EditableText>(find.byType(EditableText).last).obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
    });

    testWidgets('works in Portuguese', (tester) async {
      await pumpApp(tester, language: 'pt');

      expect(find.text('Inicia sessão para continuar.'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nome de utilizador'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Palavra-passe'), findsOneWidget);
    });
  });

  group('keyboard', () {
    testWidgets('"Next" goes through every field, skipping the show-password buttons', (tester) async {
      await pumpApp(tester);
      await openRegister(tester);

      String? focusedLabel() {
        final focused = FocusManager.instance.primaryFocus?.context;
        final field = focused?.findAncestorWidgetOfExactType<TextField>();
        return field?.decoration?.labelText;
      }

      await tester.tap(find.widgetWithText(TextFormField, 'First name'));
      await tester.pump();
      final visited = <String?>[focusedLabel()];
      for (var i = 0; i < 4; i++) {
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        visited.add(focusedLabel());
      }

      expect(visited, ['First name', 'Last name', 'Username', 'Password', 'Confirm password']);
    });
  });

  group('register', () {
    testWidgets('creates the account and opens the app', (tester) async {
      await pumpApp(tester);
      await openRegister(tester);

      await fillRegisterForm(tester);
      await submitRegister(tester);

      expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Ana Conceição'), findsOneWidget);
    });

    testWidgets('checks the fields before sending', (tester) async {
      final backend = FakeBackend();
      await pumpApp(tester, backend: backend);
      await openRegister(tester);

      await fillRegisterForm(tester, username: 'ab', password: 'short', confirm: 'different');
      await submitRegister(tester);

      expect(find.text('3 to 30 letters, numbers, . _ or -'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text("The passwords don't match"), findsOneWidget);
      expect(backend.api.callsTo('/auth/register'), isEmpty);
    });

    testWidgets('shows "username taken" on the username field', (tester) async {
      await pumpApp(tester, backend: FakeBackend()..seedUser(username: 'ana'));
      await openRegister(tester);

      await fillRegisterForm(tester);
      await submitRegister(tester);

      expect(find.text('This username is already taken.'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Dashboard'), findsNothing);
    });

    testWidgets('says when registration is turned off', (tester) async {
      await pumpApp(tester, backend: FakeBackend(registrationEnabled: false));
      await openRegister(tester);

      await fillRegisterForm(tester);
      await submitRegister(tester);

      expect(find.text('Creating new accounts is turned off.'), findsOneWidget);
    });

    testWidgets('goes back to the login screen', (tester) async {
      await pumpApp(tester);
      await openRegister(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Log in to continue.'), findsOneWidget);
    });
  });

  group('logout', () {
    testWidgets('asks first, then forgets the session and shows the login screen', (tester) async {
      final session = await pumpApp(tester, loggedIn: true);

      await openDrawerAndTap(tester, 'Log out');
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await session.read(), isNotNull);

      await openDrawerAndTap(tester, 'Log out');
      await tester.tap(find.widgetWithText(TextButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Log in to continue.'), findsOneWidget);
      expect(await session.read(), isNull);
    });
  });
}
