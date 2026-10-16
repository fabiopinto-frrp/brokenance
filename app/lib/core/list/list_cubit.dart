import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_exception.dart';

enum ListStatus { initial, loading, loaded, failure }

class ListState<D> extends Equatable {
  const ListState({this.status = ListStatus.initial, this.data, this.error, this.hidden = const {}});

  final ListStatus status;

  /// What the screen shows. Kept while reloading or after a failed reload.
  final D? data;
  final ApiException? error;

  /// Ids swiped away and waiting for "Undo" to expire. Screens leave them out.
  final Set<String> hidden;

  ListState<D> copyWith({ListStatus? status, D? data, ApiException? error, Set<String>? hidden}) => ListState(
    status: status ?? this.status,
    data: data ?? this.data,
    error: error,
    hidden: hidden ?? this.hidden,
  );

  @override
  List<Object?> get props => [status, data, error, hidden];
}

/// The shared logic of every list screen (expenses, subscriptions, savings targets, goals):
/// load, change something and reload, and delete with "Undo".
///
/// After every change the list is loaded again from the API, which computes totals, the current
/// savings target, next charge dates and goal progress, so the screen never shows stale numbers.
/// [onMoneyChanged] runs after changes that move money (the drawer's balance).
abstract class ListCubit<D> extends Cubit<ListState<D>> {
  ListCubit({this.onMoneyChanged}) : super(ListState<D>());

  final void Function()? onMoneyChanged;

  /// Loads the screen's data from the API.
  Future<D> fetch();

  /// Whether a change on this screen can move the balance.
  bool get changesMoney => false;

  Future<void> refresh() async {
    emit(state.copyWith(status: ListStatus.loading));
    try {
      final data = await fetch();
      if (!isClosed) emit(state.copyWith(status: ListStatus.loaded, data: data));
    } on ApiException catch (error) {
      if (!isClosed) emit(state.copyWith(status: ListStatus.failure, error: error));
    }
  }

  /// Runs a create or update, then reloads. Throws the [ApiException] so the form can show it.
  Future<void> save(Future<void> Function() request) async {
    await request();
    await _afterChange();
  }

  /// Hides an item right away (swipe to delete). Call [restore] on "Undo" or [delete] after.
  void hide(String id) => emit(state.copyWith(hidden: {...state.hidden, id}));

  void restore(String id) => emit(state.copyWith(hidden: {...state.hidden}..remove(id)));

  /// Sends the delete. On failure the item comes back and the error is thrown.
  Future<void> delete(String id, Future<void> Function() request) async {
    try {
      await request();
    } on ApiException {
      restore(id);
      rethrow;
    }
    await _afterChange();
    restore(id);
  }

  Future<void> _afterChange() async {
    await refresh();
    if (changesMoney) onMoneyChanged?.call();
  }
}
