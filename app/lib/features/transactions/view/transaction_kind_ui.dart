import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_destinations.dart';
import '../data/transaction.dart';

/// The texts and icon of each kind, so one screen serves Despesas, Saídas/Férias and Lazer.
extension TransactionKindUi on TransactionKind {
  IconData get icon => switch (this) {
    TransactionKind.expense => AppDestination.expenses.selectedIcon,
    TransactionKind.outing => AppDestination.outings.selectedIcon,
    TransactionKind.leisure => AppDestination.leisure.selectedIcon,
  };

  String newTitle(AppLocalizations l10n) => switch (this) {
    TransactionKind.expense => l10n.expenseNew,
    TransactionKind.outing => l10n.outingNew,
    TransactionKind.leisure => l10n.leisureNew,
  };

  String editTitle(AppLocalizations l10n) => switch (this) {
    TransactionKind.expense => l10n.expenseEdit,
    TransactionKind.outing => l10n.outingEdit,
    TransactionKind.leisure => l10n.leisureEdit,
  };

  String emptyTitle(AppLocalizations l10n) => switch (this) {
    TransactionKind.expense => l10n.expensesEmptyTitle,
    TransactionKind.outing => l10n.outingsEmptyTitle,
    TransactionKind.leisure => l10n.leisureEmptyTitle,
  };

  String emptyMessage(AppLocalizations l10n) => switch (this) {
    TransactionKind.expense => l10n.expensesEmptyMessage,
    TransactionKind.outing => l10n.outingsEmptyMessage,
    TransactionKind.leisure => l10n.leisureEmptyMessage,
  };
}
