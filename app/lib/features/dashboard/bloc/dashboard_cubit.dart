import '../../../core/list/list_cubit.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_summary.dart';

/// The dashboard reuses the list frame's loading and error handling.
class DashboardCubit extends ListCubit<DashboardSummary> {
  DashboardCubit(this.repository);

  final DashboardRepository repository;

  /// How many months the charts show (6 or 12).
  int months = 6;

  @override
  Future<DashboardSummary> fetch() => repository.summary(months: months);

  Future<void> setMonths(int value) {
    months = value;
    return refresh();
  }
}
