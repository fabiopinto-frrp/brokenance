import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_colors.dart';
import '../data/dashboard_summary.dart';
import 'chart_format.dart';

/// Balance at the end of each month (today for the current one): one line, area below it.
/// Touch a point to read its exact value.
class BalanceChart extends StatelessWidget {
  const BalanceChart({super.key, required this.months});

  final List<MonthSummary> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final locale = Localizations.localeOf(context);
    final line = theme.colorScheme.primary;
    final labelStyle = theme.textTheme.labelSmall;
    final values = [for (final month in months) month.netWorthCents / 100];
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    // Some room above and below the line, so it never touches the edges.
    final padding = (high - low).abs() < 1
        ? (high.abs() * 0.1).clamp(10, double.infinity)
        : (high - low) * 0.15;
    final labelEvery = months.length > 6 ? 2 : 1;

    return LineChart(
      LineChartData(
        minY: low - padding,
        maxY: high + padding,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: colors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => value == meta.max || value == meta.min
                  ? const SizedBox.shrink()
                  : Text(ChartFormat.compactEuros(value, locale), style: labelStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index != value || index < 0 || index >= months.length) return const SizedBox.shrink();
                // Every other month on long ranges, always the current one.
                final isLast = index == months.length - 1;
                if (!isLast && (months.length - 1 - index) % labelEvery != 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(ChartFormat.shortMonth(months[index].month, locale), style: labelStyle),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.onSurface,
            tooltipBorderRadius: const BorderRadius.all(Radius.circular(10)),
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${AppDates.monthYear(months[spot.x.toInt()].month, locale)}\n',
                  theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.surface),
                  children: [
                    TextSpan(
                      text: Money.format(months[spot.x.toInt()].netWorthCents, locale),
                      style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.surface),
                    ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final (index, value) in values.indexed) FlSpot(index.toDouble(), value)],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: line,
            barWidth: 2,
            isStrokeCapRound: true,
            // A marker on today's value only, with a ring in the card colour.
            dotData: FlDotData(
              checkToShowDot: (spot, bar) => spot.x == bar.spots.last.x,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: line,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [line.withValues(alpha: 0.18), line.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }
}
