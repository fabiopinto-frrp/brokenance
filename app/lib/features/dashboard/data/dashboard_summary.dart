import 'package:equatable/equatable.dart';

import '../../goals/data/goal.dart';

/// Money spent per category in a month, in cents (positive).
class SpendingByCategory extends Equatable {
  const SpendingByCategory({
    required this.expense,
    required this.outing,
    required this.leisure,
    required this.subscriptions,
  });

  factory SpendingByCategory.fromJson(Map<String, dynamic> json) => SpendingByCategory(
    expense: json['expense'] as int,
    outing: json['outing'] as int,
    leisure: json['leisure'] as int,
    subscriptions: json['subscription_charge'] as int,
  );

  final int expense;
  final int outing;
  final int leisure;
  final int subscriptions;

  int get total => expense + outing + leisure + subscriptions;

  @override
  List<Object?> get props => [expense, outing, leisure, subscriptions];
}

class MonthSummary extends Equatable {
  const MonthSummary({
    required this.month,
    required this.incomeCents,
    required this.spendingCents,
    required this.leftCents,
    required this.spendingByCategory,
    required this.netWorthCents,
  });

  factory MonthSummary.fromJson(Map<String, dynamic> json) => MonthSummary(
    month: json['month'] as String,
    incomeCents: json['incomeCents'] as int,
    spendingCents: json['spendingCents'] as int,
    leftCents: json['leftCents'] as int,
    spendingByCategory: SpendingByCategory.fromJson(json['spendingByCategory'] as Map<String, dynamic>),
    netWorthCents: json['netWorthCents'] as int,
  );

  /// 'YYYY-MM'
  final String month;
  final int incomeCents;
  final int spendingCents;

  /// income - spending; negative when more was spent.
  final int leftCents;
  final SpendingByCategory spendingByCategory;

  /// Balance at the end of the month (today for the current one).
  final int netWorthCents;

  @override
  List<Object?> get props => [
    month,
    incomeCents,
    spendingCents,
    leftCents,
    spendingByCategory,
    netWorthCents,
  ];
}

/// Everything the dashboard shows, from `GET /dashboard/summary`.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.netWorthCents,
    required this.months,
    required this.savingsTargetCents,
    required this.onTrack,
    required this.goals,
    required this.goalsTargetCents,
    required this.goalsSavedCents,
    required this.activeSubscriptions,
    required this.subscriptionsPerMonthCents,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final savings = json['savings'] as Map<String, dynamic>;
    final goals = json['goals'] as Map<String, dynamic>;
    final subscriptions = json['subscriptions'] as Map<String, dynamic>;
    return DashboardSummary(
      netWorthCents: json['netWorthCents'] as int,
      months: (json['months'] as List)
          .map((month) => MonthSummary.fromJson(month as Map<String, dynamic>))
          .toList(),
      savingsTargetCents: savings['targetCents'] as int?,
      onTrack: savings['onTrack'] as bool?,
      goals: (goals['items'] as List).map((goal) => Goal.fromJson(goal as Map<String, dynamic>)).toList(),
      goalsTargetCents: goals['totalTargetCents'] as int,
      goalsSavedCents: goals['totalSavedCents'] as int,
      activeSubscriptions: subscriptions['activeCount'] as int,
      subscriptionsPerMonthCents: subscriptions['averagePerMonthCents'] as int,
    );
  }

  final int netWorthCents;

  /// Oldest first; the last one is the current month.
  final List<MonthSummary> months;
  final int? savingsTargetCents;

  /// left this month >= savings target. Null without a target.
  final bool? onTrack;
  final List<Goal> goals;
  final int goalsTargetCents;
  final int goalsSavedCents;
  final int activeSubscriptions;
  final int subscriptionsPerMonthCents;

  MonthSummary get currentMonth => months.last;

  /// How much the balance moved since the end of last month. Null with a single month.
  int? get changeSinceLastMonth =>
      months.length < 2 ? null : netWorthCents - months[months.length - 2].netWorthCents;

  @override
  List<Object?> get props => [
    netWorthCents,
    months,
    savingsTargetCents,
    onTrack,
    goals,
    goalsTargetCents,
    goalsSavedCents,
    activeSubscriptions,
    subscriptionsPerMonthCents,
  ];
}
