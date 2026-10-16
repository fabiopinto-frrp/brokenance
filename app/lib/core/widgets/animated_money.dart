import 'package:material_ui/material_ui.dart';

import '../format/money.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// An amount that counts up or down to its new value when it changes. Negative values are red.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({super.key, required this.cents, this.style});

  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final color = cents < 0 ? context.colors.negative : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: cents.toDouble()),
      duration: AppDurations.slow * 2,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        Money.format(value.round(), locale),
        style: style?.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}
