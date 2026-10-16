import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/locale_cubit.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_cubit.dart';

/// Appearance (system, light, dark) and language (system, Português, English).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = context.watch<ThemeCubit>().state;
    final locale = context.watch<LocaleCubit>().state;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        _Section(
          title: l10n.settingsAppearance,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.themeDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => context.read<ThemeCubit>().setThemeMode(selection.single),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _Section(
          title: l10n.settingsLanguage,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'system', label: Text(l10n.languageSystem)),
              ButtonSegment(value: 'pt', label: Text(l10n.languagePortuguese)),
              ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
            ],
            selected: {locale?.languageCode ?? 'system'},
            onSelectionChanged: (selection) {
              final code = selection.single;
              context.read<LocaleCubit>().setLocale(code == 'system' ? null : Locale(code));
            },
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.md),
          child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        ),
        child,
      ],
    );
  }
}
