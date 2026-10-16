import 'package:equatable/equatable.dart';

enum SubscriptionPeriod { monthly, yearly }

class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.period,
    required this.billingDay,
    required this.billingMonth,
    required this.active,
    required this.nextChargeDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String,
    name: json['name'] as String,
    amountCents: json['amountCents'] as int,
    period: SubscriptionPeriod.values.byName(json['period'] as String),
    billingDay: json['billingDay'] as int,
    billingMonth: json['billingMonth'] as int?,
    active: json['active'] as bool,
    nextChargeDate: json['nextChargeDate'] as String?,
  );

  final String id;
  final String name;
  final int amountCents;
  final SubscriptionPeriod period;

  /// Day of the month, 1-31 (shorter months use their last day).
  final int billingDay;

  /// Yearly only, 1-12.
  final int? billingMonth;
  final bool active;

  /// 'YYYY-MM-DD', null when paused.
  final String? nextChargeDate;

  @override
  List<Object?> get props => [
    id,
    name,
    amountCents,
    period,
    billingDay,
    billingMonth,
    active,
    nextChargeDate,
  ];
}

class SubscriptionList extends Equatable {
  const SubscriptionList({
    required this.items,
    required this.monthlyTotalCents,
    required this.yearlyTotalCents,
    required this.averagePerMonthCents,
  });

  factory SubscriptionList.fromJson(Map<String, dynamic> json) => SubscriptionList(
    items: (json['items'] as List)
        .map((item) => Subscription.fromJson(item as Map<String, dynamic>))
        .toList(),
    monthlyTotalCents: json['monthlyTotalCents'] as int,
    yearlyTotalCents: json['yearlyTotalCents'] as int,
    averagePerMonthCents: json['averagePerMonthCents'] as int,
  );

  final List<Subscription> items;
  final int monthlyTotalCents;
  final int yearlyTotalCents;
  final int averagePerMonthCents;

  @override
  List<Object?> get props => [items, monthlyTotalCents, yearlyTotalCents, averagePerMonthCents];
}
