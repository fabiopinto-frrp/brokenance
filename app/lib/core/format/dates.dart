import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The API sends days as 'YYYY-MM-DD' strings. These helpers convert and display them.
/// Dates are plain calendar days: no times, no time zones.
abstract final class AppDates {
  static String _locale(Locale locale) => locale.languageCode == 'pt' ? 'pt_PT' : 'en_GB';

  /// '2026-10-15' -> DateTime(2026, 10, 15)
  static DateTime parse(String day) => DateTime.parse(day);

  /// DateTime(2026, 10, 15) -> '2026-10-15'
  static String toApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Today on this device, as 'YYYY-MM-DD'.
  static String today() => toApi(DateTime.now());

  /// '2026-10' for a day.
  static String monthOf(String day) => day.substring(0, 7);

  /// "15 Oct 2026" / "15 out. 2026". The same day-month-year order in both languages (the
  /// standard Portuguese short format is numeric, "15/10/2026", which reads worse in lists).
  static String day(String day, Locale locale) => DateFormat('d MMM y', _locale(locale)).format(parse(day));

  /// "October 2026" / "outubro de 2026".
  static String monthYear(String month, Locale locale) =>
      _capitalize(DateFormat.yMMMM(_locale(locale)).format(DateTime.parse('$month-01')));

  /// "10 March" / "10 de março", for a day and month with no year. Uses a leap year so that
  /// 29 February can be shown.
  static String dayAndMonth(int day, int month, Locale locale) =>
      DateFormat.MMMMd(_locale(locale)).format(DateTime(2028, month, day));

  /// "March" / "março", for a month number 1-12.
  static String monthName(int month, Locale locale) =>
      _capitalize(DateFormat.MMMM(_locale(locale)).format(DateTime(2026, month)));

  static String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
