import '../../../core/list/list_cubit.dart';
import '../data/transaction.dart';
import '../data/transaction_repository.dart';

/// One per screen: Despesas, Saídas/Férias or Lazer.
class TransactionsCubit extends ListCubit<TransactionPage> {
  TransactionsCubit(this.repository, this.kind, {super.onMoneyChanged});

  final TransactionRepository repository;
  final TransactionKind kind;

  @override
  bool get changesMoney => true;

  @override
  Future<TransactionPage> fetch() => repository.list(kind);

  Future<void> create(TransactionInput input) => save(() => repository.create(kind, input));

  Future<void> update(String id, TransactionInput input) => save(() => repository.update(id, kind, input));
}
