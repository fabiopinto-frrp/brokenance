import 'package:brokenance/core/format/dates.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  const pt = Locale('pt');
  const en = Locale('en');

  setUpAll(initializeDateFormatting);

  test('converts between the API format and dates', () {
    expect(AppDates.toApi(DateTime(2026, 3, 5)), '2026-03-05');
    expect(AppDates.parse('2026-03-05'), DateTime(2026, 3, 5));
    expect(AppDates.monthOf('2026-03-05'), '2026-03');
  });

  test('shows days the same way in both languages', () {
    expect(AppDates.day('2027-03-10', en), '10 Mar 2027');
    expect(AppDates.day('2027-03-10', pt), '10 mar. 2027');
  });

  test('names months, and shows 29 February', () {
    expect(AppDates.monthYear('2026-10', pt), 'Outubro de 2026');
    expect(AppDates.monthYear('2026-10', en), 'October 2026');
    expect(AppDates.monthName(3, pt), 'Março');
    expect(AppDates.dayAndMonth(10, 3, pt), '10 de março');
    expect(AppDates.dayAndMonth(29, 2, en), '29 February');
  });
}
