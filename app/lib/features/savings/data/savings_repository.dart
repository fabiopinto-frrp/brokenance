import '../../../core/network/api_client.dart';
import 'savings_target.dart';

class SavingsRepository {
  SavingsRepository(this._api);

  final ApiClient _api;

  /// Every target, the current one first.
  Future<List<SavingsTarget>> list() async {
    final body = await _api.get<Map<String, dynamic>>('/savings-targets');
    return (body['items'] as List)
        .map((item) => SavingsTarget.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({required int amountCents, required String effectiveDate}) =>
      _api.post<Map<String, dynamic>>(
        '/savings-targets',
        data: {'amountCents': amountCents, 'effectiveDate': effectiveDate},
      );

  Future<void> update(String id, {required int amountCents, required String effectiveDate}) =>
      _api.put<Map<String, dynamic>>(
        '/savings-targets/$id',
        data: {'amountCents': amountCents, 'effectiveDate': effectiveDate},
      );

  Future<void> delete(String id) => _api.delete('/savings-targets/$id');
}
