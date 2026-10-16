import 'package:equatable/equatable.dart';

/// Save [targetCents] to buy [name]. Progress numbers come from the API.
class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.name,
    required this.targetCents,
    required this.savedCents,
    required this.remainingCents,
    required this.progressPercent,
    required this.completed,
    required this.deadline,
    required this.estimatedMonthsLeft,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    name: json['name'] as String,
    targetCents: json['targetCents'] as int,
    savedCents: json['savedCents'] as int,
    remainingCents: json['remainingCents'] as int,
    progressPercent: json['progressPercent'] as int,
    completed: json['completed'] as bool,
    deadline: json['deadline'] as String?,
    estimatedMonthsLeft: json['estimatedMonthsLeft'] as int?,
  );

  final String id;
  final String name;
  final int targetCents;
  final int savedCents;
  final int remainingCents;

  /// saved / target, rounded down. Can pass 100.
  final int progressPercent;
  final bool completed;
  final String? deadline;

  /// At the current savings target. Null without one.
  final int? estimatedMonthsLeft;

  @override
  List<Object?> get props => [
    id,
    name,
    targetCents,
    savedCents,
    remainingCents,
    progressPercent,
    completed,
    deadline,
    estimatedMonthsLeft,
  ];
}
