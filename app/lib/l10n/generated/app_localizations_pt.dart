// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Brokenance';

  @override
  String get navDashboard => 'Resumo';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navSubscriptions => 'Subscrições';

  @override
  String get navExpenses => 'Despesas';

  @override
  String get navOutings => 'Saídas/Férias';

  @override
  String get navLeisure => 'Lazer';

  @override
  String get navSavings => 'Poupança';

  @override
  String get navGoals => 'Objetivos';

  @override
  String get navSettings => 'Definições';

  @override
  String get navOpenMenu => 'Abrir menu';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get comingSoonTitle => 'Em breve';

  @override
  String get comingSoonMessage => 'Este ecrã está a ser construído.';

  @override
  String get errorNetwork =>
      'Não foi possível contactar o servidor. Verifica a tua ligação.';

  @override
  String get errorTimeout =>
      'O servidor demorou demasiado a responder. Tenta novamente.';

  @override
  String get errorSessionExpired =>
      'A tua sessão expirou. Inicia sessão novamente.';

  @override
  String get errorUnknown => 'Algo correu mal. Tenta novamente.';

  @override
  String get retry => 'Tentar novamente';
}
