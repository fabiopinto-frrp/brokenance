import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/app_preferences.dart';

/// Light, dark or follow the system. The choice is remembered on the device.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._preferences) : super(_read(_preferences.themeMode));

  final AppPreferences _preferences;

  static ThemeMode _read(String? value) =>
      ThemeMode.values.firstWhere((mode) => mode.name == value, orElse: () => ThemeMode.system);

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _preferences.setThemeMode(mode.name);
  }
}
