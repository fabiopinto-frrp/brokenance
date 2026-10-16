import 'package:brokenance/core/format/money.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pt = Locale('pt');
  const en = Locale('en');

  group('Money.format', () {
    test('formats cents for each language', () {
      expect(Money.format(1250, pt), '12,50 €');
      expect(Money.format(1250, en), '€12.50');
      expect(Money.format(123456789, pt), '1 234 567,89 €');
      expect(Money.format(123456789, en), '€1,234,567.89');
    });

    test('shows negative and signed amounts', () {
      expect(Money.format(-4250, en), '-€42.50');
      expect(Money.format(90000, en, signed: true), '+€900.00');
      expect(Money.format(0, en, signed: true), '€0.00');
    });
  });

  group('Money.parse', () {
    test('accepts what people type, in both conventions', () {
      expect(Money.parse('12,50'), 1250);
      expect(Money.parse('12.50'), 1250);
      expect(Money.parse('12,5'), 1250);
      expect(Money.parse('12'), 1200);
      expect(Money.parse(' 12,50 € '), 1250);
      expect(Money.parse('1.234,56'), 123456);
      expect(Money.parse('1,234.56'), 123456);
      expect(Money.parse('1.234'), 123400);
      expect(Money.parse(',99'), 99);
      expect(Money.parse('0,01'), 1);
    });

    test('rejects what is not an amount', () {
      for (final input in [
        '',
        'abc',
        '12,345,6',
        '12.3456',
        '-5',
        '1e3',
        '€',
        '12,50x',
        '1,234,56',
        '12.34.5',
        '1.23,45',
      ]) {
        expect(Money.parse(input), isNull, reason: input);
      }
    });

    test('is exact: no floating point errors', () {
      expect(Money.parse('0,10')! + Money.parse('0,20')!, 30);
      expect(Money.parse('1,005'), 100500);
    });
  });
}
