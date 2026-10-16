import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/list/list_page.dart';
import '../../../core/router/app_destinations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_delete.dart';
import '../../profile/bloc/profile_cubit.dart';
import '../bloc/subscriptions_cubit.dart';
import '../data/subscription.dart';
import '../data/subscription_repository.dart';
import 'subscription_form.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionsCubit(
        context.read<SubscriptionRepository>(),
        onMoneyChanged: context.read<ProfileCubit>().refresh,
      )..refresh(),
      child: const _SubscriptionsView(),
    );
  }
}

class _SubscriptionsView extends StatelessWidget {
  const _SubscriptionsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SubscriptionsCubit>();
    final l10n = context.l10n;

    return ListPage<SubscriptionList>(
      state: cubit.state,
      onRefresh: cubit.refresh,
      addLabel: l10n.add,
      onAdd: () => showSubscriptionForm(context, cubit: cubit),
      builder: (context, list) {
        final items = list.items.where((item) => !cubit.state.hidden.contains(item.id)).toList();
        if (items.isEmpty) {
          return ListView(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                child: EmptyState(
                  icon: AppDestination.subscriptions.selectedIcon,
                  title: l10n.subscriptionsEmptyTitle,
                  message: l10n.subscriptionsEmptyMessage,
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: listPadding,
          children: [
            _TotalsCard(list: list),
            const SizedBox(height: AppSpacing.xl),
            for (final subscription in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SubscriptionTile(subscription: subscription),
              ),
          ],
        );
      },
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.list});

  final SubscriptionList list;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.subscriptionsPerMonth, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            AmountText(Money.format(list.averagePerMonthCents, locale), large: true),
            const SizedBox(height: AppSpacing.md),
            Text(
              [
                l10n.subscriptionsMonthlyTotal(Money.format(list.monthlyTotalCents, locale)),
                l10n.subscriptionsYearlyTotal(Money.format(list.yearlyTotalCents, locale)),
              ].join('   ·   '),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final paused = !subscription.active;

    final schedule = subscription.period == SubscriptionPeriod.monthly
        ? l10n.subscriptionEveryMonth(subscription.billingDay)
        : l10n.subscriptionEveryYear(
            AppDates.dayAndMonth(subscription.billingDay, subscription.billingMonth!, locale),
          );
    final next = subscription.nextChargeDate;

    void delete() => deleteWithUndo(
      context,
      cubit: cubit,
      id: subscription.id,
      request: () => cubit.repository.delete(subscription.id),
    );

    return SwipeToDelete(
      id: subscription.id,
      onDelete: delete,
      child: Card(
        child: AnimatedOpacity(
          duration: AppDurations.medium,
          opacity: paused ? 0.55 : 1,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            leading: CircleAvatar(
              backgroundColor: context.colors.surfaceHigh,
              foregroundColor: theme.colorScheme.primary,
              child: Icon(paused ? Icons.pause_rounded : Icons.autorenew_rounded, size: 20),
            ),
            title: Text(subscription.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [
                schedule,
                if (paused)
                  l10n.subscriptionPaused
                else if (next != null)
                  l10n.subscriptionNextCharge(AppDates.day(next, locale)),
              ].join('\n'),
            ),
            isThreeLine: true,
            trailing: AmountText(Money.format(subscription.amountCents, locale)),
            onTap: () =>
                showSubscriptionForm(context, cubit: cubit, subscription: subscription, onDelete: delete),
          ),
        ),
      ),
    );
  }
}
