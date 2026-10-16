import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../storage/app_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/animated_money.dart';

/// Whether the current balance is hidden (true) or shown. One switch for every place the balance
/// appears (dashboard, drawer, profile), remembered on the device.
class BalanceVisibilityCubit extends Cubit<bool> {
  BalanceVisibilityCubit(this._preferences) : super(_preferences.balanceHidden);

  final AppPreferences _preferences;

  Future<void> toggle() async {
    emit(!state);
    await _preferences.setBalanceHidden(state);
  }
}

/// The balance, or dots while it is hidden. Fades between the two.
class BalanceText extends StatelessWidget {
  const BalanceText({super.key, required this.cents, this.style});

  /// Shown instead of the amount while the balance is hidden.
  static const mask = '••••••';

  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final hidden = context.watch<BalanceVisibilityCubit>().state;
    return AnimatedSwitcher(
      duration: AppDurations.medium,
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
      child: hidden
          ? Text(
              mask,
              key: const ValueKey('hidden'),
              style: style,
              semanticsLabel: context.l10n.balanceHidden,
            )
          : AnimatedMoney(key: const ValueKey('shown'), cents: cents, style: style),
    );
  }
}

/// The eye button next to the balance.
class BalanceVisibilityButton extends StatelessWidget {
  const BalanceVisibilityButton({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    final hidden = context.watch<BalanceVisibilityCubit>().state;
    final l10n = context.l10n;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: hidden ? l10n.balanceShow : l10n.balanceHide,
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: size,
        color: context.colors.textSecondary,
      ),
      onPressed: context.read<BalanceVisibilityCubit>().toggle,
    );
  }
}
