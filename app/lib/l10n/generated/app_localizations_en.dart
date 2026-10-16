// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Brokenance';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSubscriptions => 'Subscriptions';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navOutings => 'Outings & holidays';

  @override
  String get navLeisure => 'Leisure';

  @override
  String get navSavings => 'Savings';

  @override
  String get navGoals => 'Goals';

  @override
  String get navSettings => 'Settings';

  @override
  String get navOpenMenu => 'Open menu';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonMessage => 'This screen is being built.';

  @override
  String get errorNetwork => 'Can\'t reach the server. Check your connection.';

  @override
  String get errorTimeout => 'The server took too long to answer. Try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get retry => 'Try again';
}
