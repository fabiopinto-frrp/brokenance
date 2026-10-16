import 'package:equatable/equatable.dart';

/// The user's profile, as `GET /profile` returns it. Money is in cents.
class Profile extends Equatable {
  const Profile({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.monthlyIncomeCents,
    required this.netWorthCents,
    required this.netWorthSet,
    required this.currency,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    username: json['username'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    monthlyIncomeCents: json['monthlyIncomeCents'] as int,
    netWorthCents: json['netWorthCents'] as int,
    netWorthSet: json['netWorthSet'] as bool,
    currency: json['currency'] as String,
  );

  final String username;
  final String firstName;
  final String lastName;

  /// Added to the balance on the 1st of every month.
  final int monthlyIncomeCents;

  /// The money the user has now: opening balance + every transaction.
  final int netWorthCents;

  /// False until the user types their balance for the first time.
  final bool netWorthSet;
  final String currency;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    username,
    firstName,
    lastName,
    monthlyIncomeCents,
    netWorthCents,
    netWorthSet,
    currency,
  ];
}
