import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/chart_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/dashboard_summary.dart';
import 'chart_format.dart';

/// Income and spending side by side for each month, with a legend. Touch a bar for its value.
class IncomeSpendingChart extends StatelessWidget {
  const IncomeSpendingChart({super.key, required this.months});

  final List<MonthSummary> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = context.chartColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final labelStyle = theme.textTheme.labelSmall;
    final barWidth = months.length > 6 ? 6.0 : 10.0;
    const radius = BorderRadius.vertical(top: Radius.circular(4));

    BarChartRodData rod(int cents, Color color) =>
        BarChartRodData(toY: cents / 100, color: color, width: barWidth, borderRadius: radius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          children: [
            ChartLegendItem(color: chart.income, label: l10n.dashboardIncome),
            ChartLegendItem(color: chart.spending, label: l10n.dashboardSpent),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: context.colors.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) => value == meta.max
                        ? const SizedBox.shrink()
                        : Text(ChartFormat.compactEuros(value, locale), style: labelStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        ChartFormat.shortMonth(months[value.toInt()].month, locale),
                        style: labelStyle,
                      ),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.onSurface,
                  tooltipBorderRadius: const BorderRadius.all(Radius.circular(10)),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = months[group.x];
                    final isIncome = rodIndex == 0;
                    return BarTooltipItem(
                      '${isIncome ? l10n.dashboardIncome : l10n.dashboardSpent}\n',
                      theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.surface),
                      children: [
                        TextSpan(
                          text: Money.format(isIncome ? month.incomeCents : month.spendingCents, locale),
                          style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.surface),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: [
                for (final (index, month) in months.indexed)
                  BarChartGroupData(
                    x: index,
                    barsSpace: 2,
                    barRods: [rod(month.incomeCents, chart.income), rod(month.spendingCents, chart.spending)],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}

/// A colour swatch with its name, in the text colour (never in the series colour).
class ChartLegendItem extends StatelessWidget {
  const ChartLegendItem({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.all(Radius.circular(3))),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
