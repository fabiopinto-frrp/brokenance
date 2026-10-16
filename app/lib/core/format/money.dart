import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Money is always handled as whole cents (`1250` = 12.50 €), exactly like the API.
/// Conversion to text happens only here, at the edge of the UI.
abstract final class Money {
  /// The intl locale used for a language: European formats, euro currency.
  static String _intlLocale(Locale locale) => locale.languageCode == 'pt' ? 'pt_PT' : 'en_IE';

  /// 1250 -> "12,50 €" (pt) or "€12.50" (en). With [signed], positive values get a "+".
  static String format(int cents, Locale locale, {bool signed = false, String currency = 'EUR'}) {
    final formatter = NumberFormat.simpleCurrency(locale: _intlLocale(locale), name: currency);
    final text = formatter.format(cents / 100);
    return signed && cents > 0 ? '+$text' : text;
  }

  /// Parses what the user typed into cents: "12,50", "12.5", "1.234,56", "1,234.56", "12 €".
  /// Returns null when it is not a valid amount (letters, more than 2 decimals, negative).
  static int? parse(String input) {
    final text = input.replaceAll(RegExp(r'[\s€]'), '');
    if (text.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(text)) return null;

    // The last separator is the decimal one when 1 or 2 digits follow it. Every other
    // separator groups thousands and is ignored.
    final lastSeparator = text.lastIndexOf(RegExp(r'[.,]'));
    var whole = text;
    var fraction = '';
    if (lastSeparator != -1) {
      final digitsAfter = text.length - lastSeparator - 1;
      if (digitsAfter >= 1 && digitsAfter <= 2) {
        whole = text.substring(0, lastSeparator);
        fraction = text.substring(lastSeparator + 1);
      } else if (digitsAfter != 3) {
        return null;
      }
    }

    // Thousands groups: "1.234.567" or "1,234,567", one kind of separator, groups of 3 digits,
    // and never the same separator as the decimal one.
    final groupSeparators = RegExp(r'[.,]').allMatches(whole).map((match) => match[0]).toSet();
    if (groupSeparators.isNotEmpty) {
      final decimalSeparator = whole.length < text.length ? text[whole.length] : null;
      if (groupSeparators.length > 1 ||
          groupSeparators.single == decimalSeparator ||
          !RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(whole)) {
        return null;
      }
    }

    final wholeDigits = whole.replaceAll(RegExp(r'[.,]'), '');
    if (wholeDigits.isEmpty && fraction.isEmpty) return null;
    final euros = int.tryParse(wholeDigits.isEmpty ? '0' : wholeDigits);
    final cents = int.tryParse(fraction.padRight(2, '0'));
    if (euros == null || cents == null) return null;
    return euros * 100 + cents;
  }
}
