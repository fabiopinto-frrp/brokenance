import 'package:brokenance/app.dart';
import 'package:brokenance/core/network/api_client.dart';
import 'package:brokenance/core/storage/app_preferences.dart';
import 'package:brokenance/core/storage/session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

/// Starts the whole app against [backend]. With [loggedIn], a user is created and its session
/// is saved on the "device" first, like opening the app after a previous login.
Future<MemorySessionStorage> pumpApp(
  WidgetTester tester, {
  FakeBackend? backend,
  bool loggedIn = false,
  MemorySessionStorage? session,
  String language = 'en',

  /// Values already saved on the "device" (theme, language, hidden balance...).
  Map<String, Object> stored = const {},
}) async {
  // A phone-sized screen (iPhone 15/16: 390 x 844 points).
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // Tests have no internet: use the default font instead of downloading Inter.
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({'locale': language, ...stored});

  final server = backend ?? FakeBackend();
  session ??= MemorySessionStorage();
  if (loggedIn) {
    final tokens = server.seedUser();
    await session.save(Session(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken));
  }

  final preferences = await AppPreferences.load();
  final apiClient = ApiClient(baseUrl: 'http://api.test', session: session, adapter: server.api);
  await tester.pumpWidget(BrokenanceApp(preferences: preferences, apiClient: apiClient));
  await tester.pumpAndSettle();
  return session;
}

Future<void> openDrawerAndTap(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.menu_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Types into the text field whose label is [label].
Future<void> fillField(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
}
