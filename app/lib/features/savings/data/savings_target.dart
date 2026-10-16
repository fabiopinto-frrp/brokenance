import 'package:equatable/equatable.dart';

/// A monthly savings target (Poupança). The newest one is the current one.
class SavingsTarget extends Equatable {
  const SavingsTarget({
    required this.id,
    required this.amountCents,
    required this.effectiveDate,
    required this.isCurrent,
  });

  factory SavingsTarget.fromJson(Map<String, dynamic> json) => SavingsTarget(
    id: json['id'] as String,
    amountCents: json['amountCents'] as int,
    effectiveDate: json['effectiveDate'] as String,
    isCurrent: json['isCurrent'] as bool,
  );

  final String id;
  final int amountCents;
  final String effectiveDate;
  final bool isCurrent;

  @override
  List<Object?> get props => [id, amountCents, effectiveDate, isCurrent];
}
