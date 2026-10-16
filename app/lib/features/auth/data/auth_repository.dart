import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_storage.dart';
import 'user.dart';

/// Logging in and out. The only part of the app that knows about the auth endpoints.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  SessionStorage get _session => _api.session;

  /// Fires when the session ends on its own (refresh token expired or revoked).
  Stream<void> get sessionExpired => _api.sessionExpired;

  Future<User> login({required String username, required String password}) async {
    final body = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
      authenticated: false,
    );
    return _startSession(body);
  }

  /// "Confirm password" is checked by the form: the API receives the password once.
  Future<User> register({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
  }) async {
    final body = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'firstName': firstName, 'lastName': lastName, 'username': username, 'password': password},
      authenticated: false,
    );
    return _startSession(body);
  }

  /// Changes the password. The API logs out every other device and returns new tokens for this
  /// one, which are saved so the user stays logged in here.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final body = await _api.put<Map<String, dynamic>>(
      '/auth/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    await _session.save(
      Session(accessToken: body['accessToken'] as String, refreshToken: body['refreshToken'] as String),
    );
  }

  /// The user of the session saved on this device, or null when there is none or it is over.
  /// Throws an [ApiException] when the API cannot be reached (the session is kept).
  Future<User?> currentUser() async {
    if (await _session.read() == null) return null;
    try {
      final body = await _api.get<Map<String, dynamic>>('/auth/me');
      return User.fromJson(body['user'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _session.clear();
        return null;
      }
      rethrow;
    }
  }

  /// Logs out this device. The session is forgotten right away; telling the API to revoke the
  /// refresh token is best effort (it also expires on its own).
  Future<void> logout() async {
    final session = await _session.read();
    await _session.clear();
    if (session == null) return;
    try {
      await _api.post<void>(
        '/auth/logout',
        data: {'refreshToken': session.refreshToken},
        authenticated: false,
      );
    } on ApiException {
      // Offline or already revoked: nothing else to do.
    }
  }

  Future<User> _startSession(Map<String, dynamic> body) async {
    await _session.save(
      Session(accessToken: body['accessToken'] as String, refreshToken: body['refreshToken'] as String),
    );
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }
}
