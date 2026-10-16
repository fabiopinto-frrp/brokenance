import 'package:equatable/equatable.dart';

/// The logged-in user, as `GET /auth/me`, login and register return it.
class User extends Equatable {
  const User({required this.id, required this.username, required this.firstName, required this.lastName});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    username: json['username'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
  );

  final String id;
  final String username;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [id, username, firstName, lastName];
}
