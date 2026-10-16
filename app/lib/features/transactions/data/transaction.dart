import 'package:equatable/equatable.dart';

/// The three kinds the user adds by hand. The API names them `expense`, `outing`, `leisure`.
enum TransactionKind {
  expense('expense'),
  outing('outing'),
  leisure('leisure');

  const TransactionKind(this.apiName);
  final String apiName;
}

/// An expense, outing or leisure item. [amountCents] is what was spent, always positive here
/// (the API stores it as a negative change to the balance).
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.date,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    name: json['name'] as String,
    amountCents: (json['amountCents'] as int).abs(),
    date: json['date'] as String,
    note: json['note'] as String?,
  );

  final String id;
  final String name;
  final int amountCents;

  /// 'YYYY-MM-DD'
  final String date;
  final String? note;

  @override
  List<Object?> get props => [id, name, amountCents, date, note];
}

/// What the screen shows: the latest items and this month's total.
class TransactionPage extends Equatable {
  const TransactionPage({required this.items, required this.total, required this.monthTotalCents});

  final List<Transaction> items;

  /// How many exist in total (more than [items] when there are older ones to load).
  final int total;
  final int monthTotalCents;

  @override
  List<Object?> get props => [items, total, monthTotalCents];
}
