import '../../../core/network/api_client.dart';
import 'goal.dart';

class GoalRepository {
  GoalRepository(this._api);

  final ApiClient _api;

  Future<List<Goal>> list() async {
    final body = await _api.get<Map<String, dynamic>>('/goals');
    return (body['items'] as List).map((item) => Goal.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> create(GoalInput input) => _api.post<Map<String, dynamic>>('/goals', data: input.toJson());

  Future<void> update(String id, GoalInput input) =>
      _api.put<Map<String, dynamic>>('/goals/$id', data: input.toJson());

  /// The quick "+ add to goal".
  Future<void> addContribution(String id, int amountCents) =>
      _api.post<Map<String, dynamic>>('/goals/$id/contributions', data: {'amountCents': amountCents});

  Future<void> delete(String id) => _api.delete('/goals/$id');
}

class GoalInput {
  const GoalInput({required this.name, required this.targetCents, required this.savedCents, this.deadline});

  final String name;
  final int targetCents;
  final int savedCents;
  final String? deadline;

  Map<String, dynamic> toJson() => {
    'name': name,
    'targetCents': targetCents,
    'savedCents': savedCents,
    'deadline': deadline,
  };
}
