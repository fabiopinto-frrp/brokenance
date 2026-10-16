import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../core/widgets/money_field.dart';
import '../../auth/view/auth_validators.dart';
import '../bloc/subscriptions_cubit.dart';
import '../data/subscription.dart';
import '../data/subscription_repository.dart';

/// The most days each month can have (February counts as 29: other years use the 28th).
const _maxDayInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

Future<bool> showSubscriptionForm(
  BuildContext context, {
  required SubscriptionsCubit cubit,
  Subscription? subscription,
  VoidCallback? onDelete,
}) {
  final initialAmount = subscription == null
      ? ''
      : Money.formatInput(subscription.amountCents, Localizations.localeOf(context));
  return showFormSheet(
    context,
    _SubscriptionForm(
      cubit: cubit,
      subscription: subscription,
      initialAmount: initialAmount,
      onDelete: onDelete,
    ),
  );
}

class _SubscriptionForm extends StatefulWidget {
  const _SubscriptionForm({
    required this.cubit,
    required this.initialAmount,
    this.subscription,
    this.onDelete,
  });

  final SubscriptionsCubit cubit;
  final Subscription? subscription;
  final String initialAmount;
  final VoidCallback? onDelete;

  @override
  State<_SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<_SubscriptionForm> {
  late final _name = TextEditingController(text: widget.subscription?.name);
  late final _amount = TextEditingController(text: widget.initialAmount);
  late SubscriptionPeriod _period = widget.subscription?.period ?? SubscriptionPeriod.monthly;
  late int _day = widget.subscription?.billingDay ?? DateTime.now().day;
  late int _month = widget.subscription?.billingMonth ?? DateTime.now().month;
  late bool _active = widget.subscription?.active ?? true;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final input = SubscriptionInput(
      name: _name.text.trim(),
      amountCents: MoneyField.valueOf(_amount)!,
      period: _period,
      billingDay: _day,
      billingMonth: _month,
      active: _active,
    );
    final existing = widget.subscription;
    return existing == null ? widget.cubit.create(input) : widget.cubit.update(existing.id, input);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final yearly = _period == SubscriptionPeriod.yearly;

    return FormSheet(
      title: widget.subscription == null ? l10n.subscriptionNew : l10n.subscriptionEdit,
      note: l10n.subscriptionShortMonthNote,
      onSave: _save,
      onDelete: widget.onDelete,
      fields: (submit) => [
        TextFormField(
          controller: _name,
          autofocus: widget.subscription == null,
          decoration: InputDecoration(labelText: l10n.fieldName),
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          validator: AuthValidators.required(l10n),
        ),
        const SizedBox(height: AppSpacing.md),
        MoneyField(controller: _amount, label: l10n.fieldAmount, textInputAction: TextInputAction.done),
        const SizedBox(height: AppSpacing.lg),
        SegmentedButton<SubscriptionPeriod>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: SubscriptionPeriod.monthly, label: Text(l10n.periodMonthly)),
            ButtonSegment(value: SubscriptionPeriod.yearly, label: Text(l10n.periodYearly)),
          ],
          selected: {_period},
          onSelectionChanged: (selection) => setState(() => _period = selection.single),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: InputDecoration(labelText: l10n.fieldBillingDay),
                menuMaxHeight: 320,
                items: [
                  for (var day = 1; day <= 31; day++) DropdownMenuItem(value: day, child: Text('$day')),
                ],
                onChanged: (value) => setState(() => _day = value!),
                // Revalidates when the month changes, so "30 February" is caught.
                autovalidateMode: AutovalidateMode.always,
                validator: (day) =>
                    yearly && day! > _maxDayInMonth[_month - 1] ? l10n.validationDayInMonth : null,
              ),
            ),
            if (yearly) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: _month,
                  decoration: InputDecoration(labelText: l10n.fieldBillingMonth),
                  menuMaxHeight: 320,
                  items: [
                    for (var month = 1; month <= 12; month++)
                      DropdownMenuItem(value: month, child: Text(AppDates.monthName(month, locale))),
                  ],
                  onChanged: (value) => setState(() => _month = value!),
                ),
              ),
            ],
          ],
        ),
        if (widget.subscription != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            title: Text(l10n.subscriptionActive),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
        ],
      ],
    );
  }
}
