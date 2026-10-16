import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Labels for chart axes: short months and compact amounts.
abstract final class ChartFormat {
  static String _locale(Locale locale) => locale.languageCode == 'pt' ? 'pt_PT' : 'en_GB';

  /// '2026-10' -> "Oct" / "out."
  static String shortMonth(String month, Locale locale) =>
      DateFormat.MMM(_locale(locale)).format(DateTime.parse('$month-01'));

  /// Axis amounts in euros: "€1.2K" / "1,2 mil €". [euros] is a value already divided by 100.
  static String compactEuros(double euros, Locale locale) => euros == 0
      // The compact format writes zero as "€0.00"; the other labels have no decimals.
      ? NumberFormat.simpleCurrency(locale: _locale(locale), name: 'EUR', decimalDigits: 0).format(0)
      : NumberFormat.compactSimpleCurrency(locale: _locale(locale), name: 'EUR').format(euros);
}
