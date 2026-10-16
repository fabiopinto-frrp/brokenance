import '../../../core/list/list_cubit.dart';
import '../data/savings_repository.dart';
import '../data/savings_target.dart';

/// Savings targets never change the balance.
class SavingsCubit extends ListCubit<List<SavingsTarget>> {
  SavingsCubit(this.repository);

  final SavingsRepository repository;

  @override
  Future<List<SavingsTarget>> fetch() => repository.list();

  Future<void> create({required int amountCents, required String effectiveDate}) =>
      save(() => repository.create(amountCents: amountCents, effectiveDate: effectiveDate));

  Future<void> update(String id, {required int amountCents, required String effectiveDate}) =>
      save(() => repository.update(id, amountCents: amountCents, effectiveDate: effectiveDate));
}
