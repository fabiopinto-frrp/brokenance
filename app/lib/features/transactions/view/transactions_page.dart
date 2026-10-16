import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/list/list_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/undo_delete.dart';
import '../../profile/bloc/profile_cubit.dart';
import '../bloc/transactions_cubit.dart';
import '../data/transaction.dart';
import '../data/transaction_repository.dart';
import 'transaction_form.dart';
import 'transaction_kind_ui.dart';

/// Despesas, Saídas/Férias or Lazer, depending on [kind].
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key, required this.kind});

  final TransactionKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // A new cubit per kind, so switching between the three screens never mixes their items.
      key: ValueKey(kind),
      create: (context) => TransactionsCubit(
        context.read<TransactionRepository>(),
        kind,
        onMoneyChanged: context.read<ProfileCubit>().refresh,
      )..refresh(),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<TransactionsCubit>();
    final l10n = context.l10n;

    return ListPage<TransactionPage>(
      state: cubit.state,
      onRefresh: cubit.refresh,
      addLabel: l10n.add,
      onAdd: () => showTransactionForm(context, cubit: cubit),
      builder: (context, page) {
        final items = page.items.where((item) => !cubit.state.hidden.contains(item.id)).toList();
        if (items.isEmpty) {
          return ListView(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                child: EmptyState(
                  icon: cubit.kind.icon,
                  title: cubit.kind.emptyTitle(l10n),
                  message: cubit.kind.emptyMessage(l10n),
                ),
              ),
            ],
          );
        }
        return _TransactionList(page: page, items: items);
      },
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.page, required this.items});

  final TransactionPage page;
  final List<Transaction> items;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final months = <String, List<Transaction>>{};
    for (final item in items) {
      months.putIfAbsent(AppDates.monthOf(item.date), () => []).add(item);
    }

    return ListView(
      padding: listPadding,
      children: [
        _MonthTotalCard(cents: page.monthTotalCents),
        for (final MapEntry(key: month, value: monthItems) in months.entries) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionTitle(AppDates.monthYear(month, locale)),
          for (final item in monthItems)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TransactionTile(transaction: item),
            ),
        ],
      ],
    );
  }
}

class _MonthTotalCard extends StatelessWidget {
  const _MonthTotalCard({required this.cents});

  final int cents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.transactionsThisMonth, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            AmountText(Money.format(cents, Localizations.localeOf(context)), large: true),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final note = transaction.note;

    void delete() => deleteWithUndo(
      context,
      cubit: cubit,
      id: transaction.id,
      request: () => cubit.repository.delete(transaction.id),
    );

    return SwipeToDelete(
      id: transaction.id,
      onDelete: delete,
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          leading: CircleAvatar(
            backgroundColor: context.colors.surfaceHigh,
            foregroundColor: theme.colorScheme.primary,
            child: Icon(cubit.kind.icon, size: 20),
          ),
          title: Text(transaction.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [AppDates.day(transaction.date, locale), ?note].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: AmountText(Money.format(transaction.amountCents, locale)),
          onTap: () => showTransactionForm(context, cubit: cubit, transaction: transaction, onDelete: delete),
        ),
      ),
    );
  }
}
