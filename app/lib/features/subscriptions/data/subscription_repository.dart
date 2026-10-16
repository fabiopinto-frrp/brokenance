import '../../../core/network/api_client.dart';
import 'subscription.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._api);

  final ApiClient _api;

  Future<SubscriptionList> list() async =>
      SubscriptionList.fromJson(await _api.get<Map<String, dynamic>>('/subscriptions'));

  Future<void> create(SubscriptionInput input) =>
      _api.post<Map<String, dynamic>>('/subscriptions', data: input.toJson());

  Future<void> update(String id, SubscriptionInput input) =>
      _api.put<Map<String, dynamic>>('/subscriptions/$id', data: input.toJson());

  Future<void> delete(String id) => _api.delete('/subscriptions/$id');
}

class SubscriptionInput {
  const SubscriptionInput({
    required this.name,
    required this.amountCents,
    required this.period,
    required this.billingDay,
    this.billingMonth,
    this.active = true,
  });

  final String name;
  final int amountCents;
  final SubscriptionPeriod period;
  final int billingDay;
  final int? billingMonth;
  final bool active;

  Map<String, dynamic> toJson() => {
    'name': name,
    'amountCents': amountCents,
    'period': period.name,
    'billingDay': billingDay,
    if (period == SubscriptionPeriod.yearly) 'billingMonth': billingMonth,
    'active': active,
  };
}
