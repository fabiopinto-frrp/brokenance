import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../core/widgets/money_field.dart';
import '../../auth/view/auth_validators.dart';
import '../bloc/transactions_cubit.dart';
import '../data/transaction.dart';
import '../data/transaction_repository.dart';
import 'transaction_kind_ui.dart';

/// Opens the add form, or the edit form when [transaction] is given.
Future<bool> showTransactionForm(
  BuildContext context, {
  required TransactionsCubit cubit,
  Transaction? transaction,
  VoidCallback? onDelete,
}) {
  final initialAmount = transaction == null
      ? ''
      : Money.formatInput(transaction.amountCents, Localizations.localeOf(context));
  return showFormSheet(
    context,
    _TransactionForm(
      cubit: cubit,
      transaction: transaction,
      initialAmount: initialAmount,
      onDelete: onDelete,
    ),
  );
}

class _TransactionForm extends StatefulWidget {
  const _TransactionForm({required this.cubit, required this.initialAmount, this.transaction, this.onDelete});

  final TransactionsCubit cubit;
  final Transaction? transaction;
  final String initialAmount;
  final VoidCallback? onDelete;

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  late final _name = TextEditingController(text: widget.transaction?.name);
  late final _amount = TextEditingController(text: widget.initialAmount);
  late final _note = TextEditingController(text: widget.transaction?.note);
  late String _date = widget.transaction?.date ?? AppDates.today();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final input = TransactionInput(
      name: _name.text.trim(),
      amountCents: MoneyField.valueOf(_amount)!,
      date: _date,
      note: _note.text,
    );
    final existing = widget.transaction;
    return existing == null ? widget.cubit.create(input) : widget.cubit.update(existing.id, input);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = widget.cubit.kind;
    return FormSheet(
      title: widget.transaction == null ? kind.newTitle(l10n) : kind.editTitle(l10n),
      onSave: _save,
      onDelete: widget.onDelete,
      fields: (submit) => [
        TextFormField(
          controller: _name,
          autofocus: widget.transaction == null,
          decoration: InputDecoration(labelText: l10n.fieldName),
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          validator: AuthValidators.required(l10n),
        ),
        const SizedBox(height: AppSpacing.md),
        MoneyField(controller: _amount, label: l10n.fieldAmount, textInputAction: TextInputAction.next),
        const SizedBox(height: AppSpacing.md),
        DateField(label: l10n.fieldDate, initialValue: _date, onChanged: (value) => _date = value!),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _note,
          decoration: InputDecoration(labelText: l10n.fieldNote),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          minLines: 1,
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
        ),
      ],
    );
  }
}
