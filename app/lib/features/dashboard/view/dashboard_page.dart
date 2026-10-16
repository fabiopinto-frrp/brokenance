import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/list/list_page.dart';
import '../../../core/router/app_destinations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/privacy/balance_visibility.dart';
import '../../../core/widgets/empty_state.dart';
import '../../goals/data/goal.dart';
import '../../profile/bloc/profile_cubit.dart';
import '../bloc/dashboard_cubit.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_summary.dart';
import 'balance_chart.dart';
import 'income_spending_chart.dart';
import 'spending_breakdown.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(context.read<DashboardRepository>())..refresh(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DashboardCubit>();
    final balanceSet = context.select((ProfileCubit profile) => profile.state.profile?.netWorthSet);

    return ListPage<DashboardSummary>(
      state: cubit.state,
      onRefresh: () async {
        await cubit.refresh();
        if (context.mounted) await context.read<ProfileCubit>().refresh();
      },
      builder: (context, summary) {
        if (balanceSet == false) return const _Welcome();
        final cards = <Widget>[
          _BalanceHero(summary: summary),
          _ThisMonthCard(summary: summary),
          _ChartCard(
            title: context.l10n.dashboardBalanceTitle,
            trailing: _MonthsToggle(value: cubit.months, onChanged: cubit.setMonths),
            child: SizedBox(height: 200, child: BalanceChart(months: summary.months)),
          ),
          _ChartCard(
            title: context.l10n.dashboardSpendingTitle,
            child: SpendingBreakdown(spending: summary.currentMonth.spendingByCategory),
          ),
          _ChartCard(
            title: context.l10n.dashboardIncomeVsSpending,
            child: IncomeSpendingChart(months: summary.months),
          ),
          if (summary.goals.isNotEmpty) _GoalsCard(summary: summary),
          _SubscriptionsCard(summary: summary),
        ];
        return ListView(
          padding: listPadding.copyWith(bottom: AppSpacing.xxxl),
          children: [
            for (final (index, card) in cards.indexed)
              _AppearIn(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: card,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Cards fade and slide in one after the other.
class _AppearIn extends StatelessWidget {
  const _AppearIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow * 2,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

/// Before the balance is set, the dashboard has nothing to show yet.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: EmptyState(
            icon: AppDestination.dashboard.selectedIcon,
            title: l10n.dashboardEmptyTitle,
            message: l10n.dashboardEmptyMessage,
            action: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
              onPressed: () => context.go(AppDestination.profile.path),
              child: Text(l10n.dashboardOpenProfile),
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final change = summary.changeSinceLastMonth;
    final locale = Localizations.localeOf(context);
    final hidden = context.watch<BalanceVisibilityCubit>().state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.l10n.profileBalanceTitle, style: theme.textTheme.labelMedium),
              const BalanceVisibilityButton(),
            ],
          ),
          BalanceText(cents: summary.netWorthCents, style: theme.textTheme.displayLarge),
          // The change would give the balance away, so it is hidden with it.
          if (change != null && change != 0 && !hidden) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  change > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 16,
                  color: change > 0 ? colors.positive : colors.negative,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    context.l10n.dashboardBalanceChange(Money.format(change, locale, signed: true)),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ThisMonthCard extends StatelessWidget {
  const _ThisMonthCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final locale = Localizations.localeOf(context);
    final month = summary.currentMonth;
    final target = summary.savingsTargetCents;

    Widget stat(String label, int cents) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(cents, locale),
              style: theme.textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );

    return _ChartCard(
      title: l10n.dashboardThisMonth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              stat(l10n.dashboardIncome, month.incomeCents),
              const SizedBox(width: AppSpacing.md),
              stat(l10n.dashboardSpent, month.spendingCents),
              const SizedBox(width: AppSpacing.md),
              stat(l10n.dashboardLeft, month.leftCents),
            ],
          ),
          if (target != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  summary.onTrack == true ? Icons.check_circle_rounded : Icons.info_rounded,
                  size: 20,
                  color: summary.onTrack == true ? colors.positive : colors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    summary.onTrack == true
                        ? l10n.dashboardSavingsOnTrack(Money.format(target, locale))
                        : l10n.dashboardSavingsShort(
                            Money.format(target - month.leftCents, locale),
                            Money.format(target, locale),
                          ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final goals = summary.goals.take(3).toList();

    return _ChartCard(
      title: l10n.navGoals,
      trailing: TextButton(
        onPressed: () => context.go(AppDestination.goals.path),
        child: Text(l10n.dashboardSeeAll),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dashboardGoalsTotal(
              Money.format(summary.goalsSavedCents, locale),
              Money.format(summary.goalsTargetCents, locale),
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final goal in goals) _GoalRow(goal: goal),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final color = goal.completed ? colors.positive : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(goal.name, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
              ),
              Text('${goal.progressPercent}%', style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: (goal.progressPercent / 100).clamp(0, 1),
            minHeight: 6,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            color: color,
            backgroundColor: colors.surfaceHigh,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsCard extends StatelessWidget {
  const _SubscriptionsCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
        leading: Icon(AppDestination.subscriptions.selectedIcon, color: theme.colorScheme.primary),
        title: Text(context.l10n.navSubscriptions, style: theme.textTheme.labelMedium),
        subtitle: Text(
          context.l10n.dashboardSubscriptionsSummary(
            summary.activeSubscriptions,
            Money.format(summary.subscriptionsPerMonthCents, Localizations.localeOf(context)),
          ),
          style: theme.textTheme.bodyLarge,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.go(AppDestination.subscriptions.path),
      ),
    );
  }
}

/// A card with a title row (and an optional control on the right).
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                  ?trailing,
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _MonthsToggle extends StatelessWidget {
  const _MonthsToggle({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<int>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        for (final months in [6, 12])
          ButtonSegment(
            value: months,
            label: Text(l10n.dashboardMonthsShort(months), semanticsLabel: l10n.dashboardMonths(months)),
          ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
