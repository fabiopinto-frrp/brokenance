import '../../../core/network/api_client.dart';
import 'dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  /// [months] of history, including the current one. The API applies due income and charges first.
  Future<DashboardSummary> summary({int months = 6}) async => DashboardSummary.fromJson(
    await _api.get<Map<String, dynamic>>('/dashboard/summary', query: {'months': months}),
  );
}
