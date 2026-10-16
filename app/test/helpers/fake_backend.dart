import 'package:dio/dio.dart';

import 'fake_api.dart';

/// An in-memory copy of the API's auth rules, for tests: register, login, refresh (with
/// rotation), logout and /auth/me. Other paths answer `{}`.
class FakeBackend {
  FakeBackend({this.registrationEnabled = true, this.offline = false});

  bool registrationEnabled;

  /// When true, `GET /profile` fails with a server error.
  bool failProfile = false;

  /// When true every request fails as if the server could not be reached.
  bool offline;

  final Map<String, Map<String, String>> _users = {};
  final Map<String, String> _accessTokens = {};
  final Map<String, String> _refreshTokens = {};
  int _counter = 0;

  late final FakeApi api = FakeApi(_handle);

  /// Creates a user and returns its tokens, as if it had logged in on this device before.
  ({String accessToken, String refreshToken}) seedUser({
    String username = 'fabio',
    String password = 'correct horse battery',
  }) {
    _users[username] = {
      'id': 'user-$username',
      'username': username,
      'password': password,
      'firstName': 'Fábio',
      'lastName': 'Pinto',
    };
    final session = _issue(username);
    return (accessToken: session['accessToken'] as String, refreshToken: session['refreshToken'] as String);
  }

  /// Ends every session of every user, like the refresh tokens expiring.
  void expireAllSessions() {
    _accessTokens.clear();
    _refreshTokens.clear();
  }

  FakeResponse _handle(RequestOptions request) {
    if (offline) throw DioException.connectionError(requestOptions: request, reason: 'offline');
    final body = (request.data as Map?)?.cast<String, dynamic>() ?? {};

    switch (request.path) {
      case '/auth/register':
        if (!registrationEnabled) return FakeResponse.error(403, 'registration_disabled');
        final username = (body['username'] as String).toLowerCase();
        if (_users.containsKey(username)) return FakeResponse.error(409, 'username_taken');
        _users[username] = {
          'id': 'user-$username',
          'username': username,
          'password': body['password'] as String,
          'firstName': body['firstName'] as String,
          'lastName': body['lastName'] as String,
        };
        return FakeResponse(201, _issue(username));
      case '/auth/login':
        final user = _users[(body['username'] as String).toLowerCase()];
        if (user == null || user['password'] != body['password']) {
          return FakeResponse.error(401, 'invalid_credentials');
        }
        return FakeResponse(200, _issue(user['username']!));
      case '/auth/refresh':
        final username = _refreshTokens.remove(body['refreshToken']);
        if (username == null) return FakeResponse.error(401, 'invalid_refresh_token');
        final session = _issue(username)..remove('user');
        return FakeResponse(200, session);
      case '/auth/logout':
        _refreshTokens.remove(body['refreshToken']);
        return const FakeResponse(204);
    }

    final token = (request.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');
    final username = _accessTokens[token];
    if (username == null) return FakeResponse.error(401, 'token_expired');
    final user = _users[username]!;
    switch ((request.method, request.path)) {
      case ('GET', '/auth/me'):
        return FakeResponse(200, {'user': _publicUser(username)});
      case ('PUT', '/auth/password'):
        if (user['password'] != body['currentPassword']) {
          return FakeResponse.error(400, 'invalid_current_password');
        }
        user['password'] = body['newPassword'] as String;
        _accessTokens.removeWhere((_, owner) => owner == username);
        _refreshTokens.removeWhere((_, owner) => owner == username);
        return FakeResponse(200, _issue(username)..remove('user'));
      case ('GET', '/profile'):
        if (failProfile) return FakeResponse.error(500, 'internal_error');
        return FakeResponse(200, _profile(username));
      case ('PUT', '/profile'):
        for (final key in ['firstName', 'lastName']) {
          if (body[key] != null) user[key] = body[key] as String;
        }
        if (body['monthlyIncomeCents'] != null) _money(username).income = body['monthlyIncomeCents'] as int;
        return FakeResponse(200, _profile(username));
      case ('PUT', '/profile/net-worth'):
        _money(username)
          ..netWorth = body['netWorthCents'] as int
          ..netWorthSet = true;
        return FakeResponse(200, _profile(username));
    }
    return const FakeResponse(200, {});
  }

  Map<String, dynamic> _issue(String username) {
    _counter++;
    final access = 'access-$_counter';
    final refresh = 'refresh-$_counter';
    _accessTokens[access] = username;
    _refreshTokens[refresh] = username;
    return {'user': _publicUser(username), 'accessToken': access, 'refreshToken': refresh};
  }

  final Map<String, _Money> _moneyByUser = {};
  _Money _money(String username) => _moneyByUser.putIfAbsent(username, _Money.new);

  /// The money of a user, to check what the app sent.
  ({int income, int netWorth, bool netWorthSet}) moneyOf(String username) {
    final money = _money(username);
    return (income: money.income, netWorth: money.netWorth, netWorthSet: money.netWorthSet);
  }

  Map<String, dynamic> _profile(String username) {
    final user = _users[username]!;
    final money = _money(username);
    return {
      'profile': {
        'username': username,
        'firstName': user['firstName'],
        'lastName': user['lastName'],
        'monthlyIncomeCents': money.income,
        'netWorthCents': money.netWorth,
        'netWorthSet': money.netWorthSet,
        'currency': 'EUR',
        'timezone': 'Europe/Lisbon',
      },
    };
  }

  Map<String, String> _publicUser(String username) {
    final user = _users[username]!;
    return {
      'id': user['id']!,
      'username': user['username']!,
      'firstName': user['firstName']!,
      'lastName': user['lastName']!,
    };
  }
}

class _Money {
  int income = 0;
  int netWorth = 0;
  bool netWorthSet = false;
}
