import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../format/money.dart';
import '../l10n/l10n.dart';

/// The largest amount the API accepts: 10 000 000,00 €.
const maxAmountCents = 1000000000;

/// An input for money. The user types euros ("12,50" or "12.50"), the form gets cents.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.allowNegative = false,
    this.allowZero = false,
    this.optional = false,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool allowNegative;
  final bool allowZero;

  /// When true the field can be left empty ([valueOf] then gives null).
  final bool optional;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// The cents typed in [controller], or null when it is not a valid amount.
  static int? valueOf(TextEditingController controller) => Money.parseSigned(controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: allowNegative),
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(allowNegative ? r'[-0-9.,\s]' : r'[0-9.,\s]')),
        LengthLimitingTextInputFormatter(16),
      ],
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: InputDecoration(labelText: label, suffixText: '€'),
      validator: (value) {
        final cents = Money.parseSigned(value ?? '');
        if (value == null || value.trim().isEmpty) return optional ? null : l10n.validationRequired;
        if (cents == null || (!allowNegative && cents < 0)) return l10n.validationAmount;
        if (cents == 0 && !allowZero) return l10n.validationAmount;
        if (cents.abs() > maxAmountCents) return l10n.validationAmountTooLarge;
        return null;
      },
    );
  }
}
