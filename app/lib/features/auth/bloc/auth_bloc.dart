import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/user.dart';

// ---------- Events ----------

sealed class AuthEvent {
  const AuthEvent();
}

/// The app started: restore the saved session, if any.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Login or register succeeded.
final class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn(this.user);
  final User user;
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class _AuthSessionExpired extends AuthEvent {
  const _AuthSessionExpired();
}

// ---------- State ----------

enum AuthStatus {
  /// Checking the saved session (splash screen).
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState._(this.status, {this.user, this.sessionExpired = false});

  const AuthState.unknown() : this._(AuthStatus.unknown);

  /// [user] can be null when the app starts offline with a saved session: the user is still
  /// logged in, the details load when the API is reachable again.
  const AuthState.authenticated(User? user) : this._(AuthStatus.authenticated, user: user);

  /// [sessionExpired] is true when the session ended on its own, so the login screen can say why.
  const AuthState.unauthenticated({bool sessionExpired = false})
    : this._(AuthStatus.unauthenticated, sessionExpired: sessionExpired);

  final AuthStatus status;
  final User? user;
  final bool sessionExpired;

  @override
  List<Object?> get props => [status, user, sessionExpired];
}

// ---------- Bloc ----------

/// App-wide login state. The router listens to it to show the login screen or the app.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedIn>((event, emit) => emit(AuthState.authenticated(event.user)));
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<_AuthSessionExpired>(_onSessionExpired);

    _expiredSubscription = _repository.sessionExpired.listen((_) => add(const _AuthSessionExpired()));
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _expiredSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _repository.currentUser();
      emit(user == null ? const AuthState.unauthenticated() : AuthState.authenticated(user));
    } on ApiException {
      // The API is unreachable but a session is saved: stay logged in.
      emit(const AuthState.authenticated(null));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthState.unauthenticated());
  }

  void _onSessionExpired(_AuthSessionExpired event, Emitter<AuthState> emit) {
    if (state.status == AuthStatus.authenticated) {
      emit(const AuthState.unauthenticated(sessionExpired: true));
    }
  }

  @override
  Future<void> close() {
    _expiredSubscription.cancel();
    return super.close();
  }
}
