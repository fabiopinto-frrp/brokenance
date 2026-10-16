import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// The translated strings: `context.l10n.navExpenses`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
