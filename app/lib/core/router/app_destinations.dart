import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';

/// Every screen reachable from the drawer. Paths are fixed and do not change with the language.
enum AppDestination {
  dashboard('/dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  profile('/profile', Icons.person_outline_rounded, Icons.person_rounded),
  subscriptions('/subscricoes', Icons.autorenew_rounded, Icons.autorenew_rounded),
  expenses('/despesas', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  outings('/saidas-ferias', Icons.flight_takeoff_rounded, Icons.flight_takeoff_rounded),
  leisure('/lazer', Icons.sports_esports_outlined, Icons.sports_esports_rounded),
  savings('/poupanca', Icons.savings_outlined, Icons.savings_rounded),
  goals('/objetivos', Icons.flag_outlined, Icons.flag_rounded),
  settings('/definicoes', Icons.tune_rounded, Icons.tune_rounded);

  const AppDestination(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// The main sections, in drawer order. Settings is shown apart, at the bottom.
  static const main = [dashboard, profile, subscriptions, expenses, outings, leisure, savings, goals];

  String label(AppLocalizations l10n) => switch (this) {
    dashboard => l10n.navDashboard,
    profile => l10n.navProfile,
    subscriptions => l10n.navSubscriptions,
    expenses => l10n.navExpenses,
    outings => l10n.navOutings,
    leisure => l10n.navLeisure,
    savings => l10n.navSavings,
    goals => l10n.navGoals,
    settings => l10n.navSettings,
  };

  /// The destination for a location such as '/despesas' or '/despesas/123'.
  static AppDestination? fromLocation(String location) {
    for (final destination in values) {
      if (location == destination.path || location.startsWith('${destination.path}/')) return destination;
    }
    return null;
  }
}
