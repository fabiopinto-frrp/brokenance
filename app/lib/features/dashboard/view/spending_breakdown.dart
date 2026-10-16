import 'package:material_ui/material_ui.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/chart_colors.dart';
import '../data/dashboard_summary.dart';

/// This month's spending split by category: one stacked bar (part of a whole) and a row per
/// category with its name, amount and share, so the colours are never the only label.
class SpendingBreakdown extends StatelessWidget {
  const SpendingBreakdown({super.key, required this.spending});

  final SpendingByCategory spending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chart = context.chartColors;
    final theme = Theme.of(context);
    final total = spending.total;

    if (total == 0) {
      return Text(l10n.dashboardSpendingEmpty, style: theme.textTheme.bodyMedium);
    }

    final categories = [
      (label: l10n.navExpenses, cents: spending.expense, color: chart.expense),
      (label: l10n.navOutings, cents: spending.outing, color: chart.outing),
      (label: l10n.navLeisure, cents: spending.leisure, color: chart.leisure),
      (label: l10n.navSubscriptions, cents: spending.subscriptions, color: chart.subscriptions),
    ];
    final present = categories.where((category) => category.cents > 0).toList();
    final locale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The bar grows in from the left; a 2px gap in the card colour separates the segments.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppDurations.slow * 2,
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) => ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            child: SizedBox(
              height: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Row(
                    // The segments are empty boxes: stretch them to the bar's height.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, category) in present.indexed) ...[
                        if (index > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: category.cents,
                          child: ColoredBox(color: category.color),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: category.cents > 0 ? category.color : context.colors.border,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(category.label, style: theme.textTheme.bodyLarge)),
                Text(
                  Money.format(category.cents, locale),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${(category.cents * 100 / total).round()}%',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
