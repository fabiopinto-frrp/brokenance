import 'package:brokenance/features/dashboard/view/chart_format.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('axis amounts are compact and zero has no decimals', () {
    expect(ChartFormat.compactEuros(0, const Locale('en')), '€0');
    expect(ChartFormat.compactEuros(400, const Locale('en')), '€400');
    expect(ChartFormat.compactEuros(2500, const Locale('en')), '€2.5k');
    expect(ChartFormat.compactEuros(0, const Locale('pt')), '0 €');
  });

  test('short month names per language', () {
    expect(ChartFormat.shortMonth('2026-10', const Locale('en')), 'Oct');
    expect(ChartFormat.shortMonth('2026-10', const Locale('pt')), 'out.');
  });
}
