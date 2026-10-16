import '../../../core/format/dates.dart';
import '../../../core/network/api_client.dart';
import 'transaction.dart';

class TransactionRepository {
  TransactionRepository(this._api);

  final ApiClient _api;

  /// The newest [limit] items of [kind], and the total spent this month.
  Future<TransactionPage> list(TransactionKind kind, {int limit = 100}) async {
    final today = AppDates.today();
    final responses = await Future.wait([
      _api.get<Map<String, dynamic>>('/transactions', query: {'type': kind.apiName, 'limit': limit}),
      _api.get<Map<String, dynamic>>(
        '/transactions',
        query: {'type': kind.apiName, 'from': '${AppDates.monthOf(today)}-01', 'to': today, 'limit': 500},
      ),
    ]);
    List<Transaction> items(Map<String, dynamic> body) =>
        (body['items'] as List).map((item) => Transaction.fromJson(item as Map<String, dynamic>)).toList();

    return TransactionPage(
      items: items(responses[0]),
      total: responses[0]['total'] as int,
      monthTotalCents: items(responses[1]).fold(0, (sum, item) => sum + item.amountCents),
    );
  }

  Future<void> create(TransactionKind kind, TransactionInput input) =>
      _api.post<Map<String, dynamic>>('/transactions', data: input.toJson(kind));

  Future<void> update(String id, TransactionKind kind, TransactionInput input) =>
      _api.put<Map<String, dynamic>>('/transactions/$id', data: input.toJson(kind));

  Future<void> delete(String id) => _api.delete('/transactions/$id');
}

/// What the form sends.
class TransactionInput {
  const TransactionInput({required this.name, required this.amountCents, required this.date, this.note});

  final String name;
  final int amountCents;
  final String date;
  final String? note;

  Map<String, dynamic> toJson(TransactionKind kind) => {
    'type': kind.apiName,
    'name': name,
    'amountCents': amountCents,
    'date': date,
    'note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
  };
}
