import '../../../core/list/list_cubit.dart';
import '../data/subscription.dart';
import '../data/subscription_repository.dart';

class SubscriptionsCubit extends ListCubit<SubscriptionList> {
  SubscriptionsCubit(this.repository, {super.onMoneyChanged});

  final SubscriptionRepository repository;

  /// A subscription added on its billing day is charged right away.
  @override
  bool get changesMoney => true;

  @override
  Future<SubscriptionList> fetch() => repository.list();

  Future<void> create(SubscriptionInput input) => save(() => repository.create(input));

  Future<void> update(String id, SubscriptionInput input) => save(() => repository.update(id, input));

  /// The switch on each row.
  Future<void> setActive(Subscription subscription, bool active) => update(
    subscription.id,
    SubscriptionInput(
      name: subscription.name,
      amountCents: subscription.amountCents,
      period: subscription.period,
      billingDay: subscription.billingDay,
      billingMonth: subscription.billingMonth,
      active: active,
    ),
  );
}
