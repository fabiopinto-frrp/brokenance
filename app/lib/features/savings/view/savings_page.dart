import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/list/list_page.dart';
import '../../../core/router/app_destinations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/undo_delete.dart';
import '../bloc/savings_cubit.dart';
import '../data/savings_repository.dart';
import '../data/savings_target.dart';

/// Poupança: the current monthly savings target and the history of older ones.
class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SavingsCubit(context.read<SavingsRepository>())..refresh(),
      child: const _SavingsView(),
    );
  }
}

class _SavingsView extends StatelessWidget {
  const _SavingsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SavingsCubit>();
    final l10n = context.l10n;

    return ListPage<List<SavingsTarget>>(
      state: cubit.state,
      onRefresh: cubit.refresh,
      addLabel: l10n.add,
      onAdd: () => _showForm(context, cubit),
      builder: (context, targets) {
        final visible = targets.where((target) => !cubit.state.hidden.contains(target.id)).toList();
        if (visible.isEmpty) {
          return ListView(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                child: EmptyState(
                  icon: AppDestination.savings.selectedIcon,
                  title: l10n.savingsEmptyTitle,
                  message: l10n.savingsEmptyMessage,
                ),
              ),
            ],
          );
        }
        // While the current one is swiped away (Undo pending), the next one shows as the main card.
        final current = visible.first;
        final history = visible.skip(1).toList();
        return ListView(
          padding: listPadding,
          children: [
            _TargetTile(target: current, main: true),
            if (history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(l10n.savingsHistory),
              for (final target in history)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TargetTile(target: target),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({required this.target, this.main = false});

  final SavingsTarget target;
  final bool main;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SavingsCubit>();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    void delete() => deleteWithUndo(
      context,
      cubit: cubit,
      id: target.id,
      request: () => cubit.repository.delete(target.id),
    );
    void edit() => _showForm(context, cubit, target: target, onDelete: delete);

    final since = l10n.savingsSince(AppDates.day(target.effectiveDate, locale));

    return SwipeToDelete(
      id: target.id,
      onDelete: delete,
      child: Card(
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: edit,
          child: main
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(l10n.savingsCurrentLabel, style: theme.textTheme.labelMedium)),
                          Icon(Icons.edit_outlined, size: 18, color: context.colors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AmountText(
                        Money.format(target.amountCents, locale),
                        large: true,
                        color: context.colors.positive,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(since, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(since, style: theme.textTheme.bodyMedium),
                  trailing: AmountText(
                    Money.format(target.amountCents, locale),
                    color: context.colors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }
}

Future<bool> _showForm(
  BuildContext context,
  SavingsCubit cubit, {
  SavingsTarget? target,
  VoidCallback? onDelete,
}) {
  final initialAmount = target == null
      ? ''
      : Money.formatInput(target.amountCents, Localizations.localeOf(context));
  return showFormSheet(
    context,
    _SavingsForm(cubit: cubit, target: target, initialAmount: initialAmount, onDelete: onDelete),
  );
}

class _SavingsForm extends StatefulWidget {
  const _SavingsForm({required this.cubit, required this.initialAmount, this.target, this.onDelete});

  final SavingsCubit cubit;
  final SavingsTarget? target;
  final String initialAmount;
  final VoidCallback? onDelete;

  @override
  State<_SavingsForm> createState() => _SavingsFormState();
}

class _SavingsFormState extends State<_SavingsForm> {
  late final _amount = TextEditingController(text: widget.initialAmount);
  late String _date = widget.target?.effectiveDate ?? AppDates.today();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final amount = MoneyField.valueOf(_amount)!;
    final existing = widget.target;
    return existing == null
        ? widget.cubit.create(amountCents: amount, effectiveDate: _date)
        : widget.cubit.update(existing.id, amountCents: amount, effectiveDate: _date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isNew = widget.target == null;
    return FormSheet(
      title: isNew ? l10n.savingsNew : l10n.savingsEdit,
      note: isNew ? l10n.savingsNewNote : null,
      onSave: _save,
      onDelete: widget.onDelete,
      fields: (submit) => [
        MoneyField(
          controller: _amount,
          label: l10n.fieldAmount,
          autofocus: isNew,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submit(),
        ),
        const SizedBox(height: AppSpacing.md),
        DateField(label: l10n.fieldEffectiveDate, initialValue: _date, onChanged: (value) => _date = value!),
      ],
    );
  }
}
