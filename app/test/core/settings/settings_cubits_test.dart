import 'package:bloc_test/bloc_test.dart';
import 'package:brokenance/core/l10n/locale_cubit.dart';
import 'package:brokenance/core/storage/app_preferences.dart';
import 'package:brokenance/core/theme/theme_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await AppPreferences.load();
  });

  group('ThemeCubit', () {
    test('follows the system by default', () {
      expect(ThemeCubit(preferences).state, ThemeMode.system);
    });

    blocTest<ThemeCubit, ThemeMode>(
      'changes and remembers the theme',
      build: () => ThemeCubit(preferences),
      act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
      expect: () => [ThemeMode.dark],
      verify: (_) => expect(ThemeCubit(preferences).state, ThemeMode.dark),
    );
  });

  group('LocaleCubit', () {
    test('follows the device by default', () {
      expect(LocaleCubit(preferences).state, isNull);
    });

    blocTest<LocaleCubit, Locale?>(
      'changes and remembers the language, and can go back to the device language',
      build: () => LocaleCubit(preferences),
      act: (cubit) async {
        await cubit.setLocale(const Locale('pt'));
        expect(LocaleCubit(preferences).state, const Locale('pt'));
        await cubit.setLocale(null);
      },
      expect: () => [const Locale('pt'), null],
      verify: (_) => expect(LocaleCubit(preferences).state, isNull),
    );

    test('ignores a stored language the app does not support', () async {
      await preferences.setLocale('fr');
      expect(LocaleCubit(preferences).state, isNull);
    });
  });
}
