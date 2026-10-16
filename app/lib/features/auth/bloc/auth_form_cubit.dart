import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/user.dart';
import 'auth_bloc.dart';

enum AuthFormStatus { idle, submitting, failure }

class AuthFormState extends Equatable {
  const AuthFormState({this.status = AuthFormStatus.idle, this.error});

  final AuthFormStatus status;

  /// The API error of the last attempt, when [status] is failure.
  final ApiException? error;

  bool get isSubmitting => status == AuthFormStatus.submitting;

  @override
  List<Object?> get props => [status, error];
}

/// Sends the login or register form. On success it tells [AuthBloc], and the router opens the app.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit(this._authBloc) : super(const AuthFormState());

  final AuthBloc _authBloc;

  Future<void> submit(Future<User> Function() request) async {
    if (state.isSubmitting) return;
    emit(const AuthFormState(status: AuthFormStatus.submitting));
    try {
      final user = await request();
      _authBloc.add(AuthLoggedIn(user));
    } on ApiException catch (error) {
      emit(AuthFormState(status: AuthFormStatus.failure, error: error));
    }
  }

  /// Clears the error, for example when the user edits a field again.
  void clearError() {
    if (state.status == AuthFormStatus.failure) emit(const AuthFormState());
  }
}
