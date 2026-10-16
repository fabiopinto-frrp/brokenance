import '../../../core/list/list_cubit.dart';
import '../data/goal.dart';
import '../data/goal_repository.dart';

/// Goals never change the balance.
class GoalsCubit extends ListCubit<List<Goal>> {
  GoalsCubit(this.repository);

  final GoalRepository repository;

  @override
  Future<List<Goal>> fetch() => repository.list();

  Future<void> create(GoalInput input) => save(() => repository.create(input));

  Future<void> update(String id, GoalInput input) => save(() => repository.update(id, input));

  Future<void> addContribution(String id, int amountCents) =>
      save(() => repository.addContribution(id, amountCents));
}
