import '../../../core/network/api_client.dart';
import 'profile.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  /// The API applies any due income and subscription charges first, so the balance is current.
  Future<Profile> get() async => _read(await _api.get<Map<String, dynamic>>('/profile'));

  /// Sends only the fields that are given.
  Future<Profile> update({String? firstName, String? lastName, int? monthlyIncomeCents}) async {
    final body = await _api.put<Map<String, dynamic>>(
      '/profile',
      data: {'firstName': ?firstName, 'lastName': ?lastName, 'monthlyIncomeCents': ?monthlyIncomeCents},
    );
    return _read(body);
  }

  /// The first time it becomes the opening balance, later the difference is an adjustment.
  Future<Profile> setNetWorth(int netWorthCents) async {
    final body = await _api.put<Map<String, dynamic>>(
      '/profile/net-worth',
      data: {'netWorthCents': netWorthCents},
    );
    return _read(body);
  }

  Profile _read(Map<String, dynamic> body) => Profile.fromJson(body['profile'] as Map<String, dynamic>);
}
