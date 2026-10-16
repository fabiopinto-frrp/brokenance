import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../data/profile.dart';
import '../data/profile_repository.dart';

enum ProfileStatus { initial, loading, loaded, failure }

class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.initial, this.profile, this.error});

  final ProfileStatus status;

  /// Kept while reloading or after a failed reload, so the screen does not go blank.
  final Profile? profile;
  final ApiException? error;

  @override
  List<Object?> get props => [status, profile, error];
}

/// The profile and the balance, app-wide: the drawer and the Profile screen read it, and other
/// screens call [refresh] after changing money. It loads on login and clears on logout.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, AuthBloc authBloc) : super(const ProfileState()) {
    _authSubscription = authBloc.stream.listen(_onAuthChanged);
    _onAuthChanged(authBloc.state);
  }

  final ProfileRepository _repository;
  late final StreamSubscription<AuthState> _authSubscription;

  void _onAuthChanged(AuthState auth) {
    if (auth.status == AuthStatus.authenticated && state.status == ProfileStatus.initial) {
      refresh();
    } else if (auth.status == AuthStatus.unauthenticated && state.status != ProfileStatus.initial) {
      emit(const ProfileState());
    }
  }

  /// Loads the profile again. Errors are kept in the state (the screen offers "Try again").
  Future<void> refresh() async {
    emit(ProfileState(status: ProfileStatus.loading, profile: state.profile));
    try {
      emit(ProfileState(status: ProfileStatus.loaded, profile: await _repository.get()));
    } on ApiException catch (error) {
      emit(ProfileState(status: ProfileStatus.failure, profile: state.profile, error: error));
    }
  }

  // The changes below throw an ApiException on failure, so the form that called them can show it.

  Future<void> updateName({required String firstName, required String lastName}) =>
      _save(() => _repository.update(firstName: firstName, lastName: lastName));

  Future<void> updateMonthlyIncome(int cents) => _save(() => _repository.update(monthlyIncomeCents: cents));

  Future<void> setNetWorth(int cents) => _save(() => _repository.setNetWorth(cents));

  Future<void> _save(Future<Profile> Function() request) async {
    final profile = await request();
    emit(ProfileState(status: ProfileStatus.loaded, profile: profile));
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
