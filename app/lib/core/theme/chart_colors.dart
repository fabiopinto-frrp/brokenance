import 'package:material_ui/material_ui.dart';

/// Chart colours, from a categorical palette checked for colour-blind readers (protan, deutan) and
/// for contrast against the cards, in light and dark mode. Each entity keeps its colour in every
/// chart; text never uses these colours (labels stay in the text colours).
///
/// Light mode's aqua and yellow are below 3:1 against white cards, so every category is always
/// shown with its name and amount next to the colour.
@immutable
class ChartColors extends ThemeExtension<ChartColors> {
  const ChartColors({
    required this.expense,
    required this.outing,
    required this.leisure,
    required this.subscriptions,
    required this.income,
    required this.spending,
  });

  // Spending categories, in this fixed order (adjacent pairs validated in this order).
  final Color expense;
  final Color outing;
  final Color leisure;
  final Color subscriptions;

  // Income vs spending, a separate pair.
  final Color income;
  final Color spending;

  static const light = ChartColors(
    expense: Color(0xFF2A78D6),
    outing: Color(0xFFEB6834),
    leisure: Color(0xFF1BAF7A),
    subscriptions: Color(0xFFEDA100),
    income: Color(0xFF6250D6),
    spending: Color(0xFFE34948),
  );

  static const dark = ChartColors(
    expense: Color(0xFF3987E5),
    outing: Color(0xFFD95926),
    leisure: Color(0xFF199E70),
    subscriptions: Color(0xFFC98500),
    income: Color(0xFF9085E9),
    spending: Color(0xFFE66767),
  );

  @override
  ChartColors copyWith() => this;

  @override
  ChartColors lerp(ChartColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return ChartColors(
      expense: mix(expense, other.expense),
      outing: mix(outing, other.outing),
      leisure: mix(leisure, other.leisure),
      subscriptions: mix(subscriptions, other.subscriptions),
      income: mix(income, other.income),
      spending: mix(spending, other.spending),
    );
  }
}

extension ChartColorsContext on BuildContext {
  ChartColors get chartColors => Theme.of(this).extension<ChartColors>()!;
}
