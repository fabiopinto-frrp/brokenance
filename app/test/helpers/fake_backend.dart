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
    final listResponse = _lists(username, request, body);
    if (listResponse != null) return listResponse;
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

  /// Sets a user's balance as if they had typed it in Profile.
  void setBalance(String username, int cents) => _money(username)
    ..netWorth = cents
    ..netWorthSet = true;

  /// The money of a user, to check what the app sent.
  ({int income, int netWorth, bool netWorthSet}) moneyOf(String username) {
    final money = _money(username);
    return (income: money.income, netWorth: money.netWorth, netWorthSet: money.netWorthSet);
  }

  // ---------- Lists: a simplified copy of the API's rules ----------

  final Map<String, List<Map<String, dynamic>>> _transactions = {};
  final Map<String, List<Map<String, dynamic>>> _subscriptions = {};
  final Map<String, List<Map<String, dynamic>>> _savings = {};
  final Map<String, List<Map<String, dynamic>>> _goals = {};

  /// "Today" for the fake API: the same day as the device, like the real API in Lisbon.
  String today = DateTime.now().toIso8601String().substring(0, 10);

  List<Map<String, dynamic>> transactionsOf(String username) => _transactions.putIfAbsent(username, () => []);
  List<Map<String, dynamic>> subscriptionsOf(String username) =>
      _subscriptions.putIfAbsent(username, () => []);
  List<Map<String, dynamic>> savingsOf(String username) => _savings.putIfAbsent(username, () => []);
  List<Map<String, dynamic>> goalsOf(String username) => _goals.putIfAbsent(username, () => []);

  FakeResponse? _lists(String username, RequestOptions request, Map<String, dynamic> body) {
    final segments = request.path.split('/').where((segment) => segment.isNotEmpty).toList();
    final collection = segments.isEmpty ? '' : segments.first;
    final id = segments.length > 1 ? segments[1] : null;
    final method = request.method;

    switch (collection) {
      case 'dashboard':
        return FakeResponse(
          200,
          _dashboard(username, int.parse('${request.queryParameters['months'] ?? 6}')),
        );
      case 'transactions':
        return _crud(
          transactionsOf(username),
          method,
          id,
          body,
          list: () {
            final query = request.queryParameters;
            final types = (query['type'] as String?)?.split(',');
            var items = transactionsOf(username).where((item) {
              final date = item['date'] as String;
              return (types == null || types.contains(item['type'])) &&
                  (query['from'] == null || date.compareTo(query['from'] as String) >= 0) &&
                  (query['to'] == null || date.compareTo(query['to'] as String) <= 0);
            }).toList()..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
            final total = items.length;
            items = items.take(int.parse('${query['limit'] ?? 100}')).toList();
            return {'items': items, 'total': total};
          },
          toItem: (body, existing) {
            final date = (body['date'] as String?) ?? today;
            if (date.compareTo(today) > 0) throw FakeResponse.error(400, 'date_in_future');
            final amount = -(body['amountCents'] as int);
            _money(username).netWorth += amount - ((existing?['amountCents'] as int?) ?? 0);
            return {
              'type': body['type'],
              'name': body['name'],
              'amountCents': amount,
              'date': date,
              'note': body['note'],
            };
          },
          onDelete: (item) => _money(username).netWorth -= item['amountCents'] as int,
        );
      case 'subscriptions':
        return _crud(
          subscriptionsOf(username),
          method,
          id,
          body,
          list: () {
            final items = subscriptionsOf(username);
            int sum(String period) => items
                .where((item) => item['active'] == true && item['period'] == period)
                .fold(0, (total, item) => total + (item['amountCents'] as int));
            return {
              'items': [
                for (final item in items) {...item, 'nextChargeDate': _nextCharge(item)},
              ],
              'monthlyTotalCents': sum('monthly'),
              'yearlyTotalCents': sum('yearly'),
              'averagePerMonthCents': sum('monthly') + (sum('yearly') / 12).round(),
            };
          },
          toItem: (body, existing) => {
            'name': body['name'],
            'amountCents': body['amountCents'],
            'period': body['period'] ?? 'monthly',
            'billingDay': body['billingDay'],
            'billingMonth': body['period'] == 'yearly' ? body['billingMonth'] : null,
            'active': body['active'] ?? true,
          },
        );
      case 'savings-targets':
        return _crud(
          savingsOf(username),
          method,
          id,
          body,
          list: () {
            final items = [...savingsOf(username)]
              ..sort((a, b) => (b['effectiveDate'] as String).compareTo(a['effectiveDate'] as String));
            return {
              'items': [
                for (final (index, item) in items.indexed) {...item, 'isCurrent': index == 0},
              ],
            };
          },
          toItem: (body, existing) {
            final date = (body['effectiveDate'] as String?) ?? today;
            if (date.compareTo(today) > 0) throw FakeResponse.error(400, 'date_in_future');
            return {'amountCents': body['amountCents'], 'effectiveDate': date};
          },
        );
      case 'goals':
        if (method == 'POST' && segments.length == 3 && segments[2] == 'contributions') {
          final goal = goalsOf(username).where((item) => item['id'] == id).firstOrNull;
          if (goal == null) return FakeResponse.error(404, 'goal_not_found');
          goal['savedCents'] = (goal['savedCents'] as int) + (body['amountCents'] as int);
          return FakeResponse(200, {'goal': _goalView(username, goal)});
        }
        return _crud(
          goalsOf(username),
          method,
          id,
          body,
          list: () => {
            'items': [for (final goal in goalsOf(username)) _goalView(username, goal)],
          },
          toItem: (body, existing) => {
            'name': body['name'],
            'targetCents': body['targetCents'],
            'savedCents': body['savedCents'] ?? 0,
            'deadline': body['deadline'],
          },
        );
    }
    return null;
  }

  /// The last [count] months: spending per category from the transactions, the balance at the end
  /// of each month worked back from today's balance.
  Map<String, dynamic> _dashboard(String username, int count) {
    final now = DateTime.parse(today);
    final months = [
      for (var i = count - 1; i >= 0; i--)
        '${DateTime(now.year, now.month - i).year}-${'${DateTime(now.year, now.month - i).month}'.padLeft(2, '0')}',
    ];
    var balance = _money(username).netWorth;
    final summaries = <Map<String, dynamic>>[];
    for (final month in months.reversed) {
      final items = transactionsOf(username).where((item) => (item['date'] as String).startsWith(month));
      int spent(String type) => items
          .where((item) => item['type'] == type)
          .fold(0, (sum, item) => sum - (item['amountCents'] as int));
      final byCategory = {
        'expense': spent('expense'),
        'outing': spent('outing'),
        'leisure': spent('leisure'),
        'subscription_charge': 0,
      };
      final spending = byCategory.values.fold(0, (a, b) => a + b);
      summaries.insert(0, {
        'month': month,
        'incomeCents': 0,
        'spendingCents': spending,
        'leftCents': -spending,
        'spendingByCategory': byCategory,
        'netWorthCents': balance,
      });
      balance += spending;
    }
    final savings = [...savingsOf(username)]
      ..sort((a, b) => (b['effectiveDate'] as String).compareTo(a['effectiveDate'] as String));
    final target = savings.isEmpty ? null : savings.first['amountCents'] as int;
    final left = summaries.last['leftCents'] as int;
    final goals = [for (final goal in goalsOf(username)) _goalView(username, goal)];
    final subscriptions =
        _lists(username, RequestOptions(path: '/subscriptions'), {})!.body as Map<String, dynamic>;
    return {
      'netWorthCents': _money(username).netWorth,
      'currentMonth': summaries.last,
      'months': summaries,
      'savings': {
        'targetCents': target,
        'leftThisMonthCents': left,
        'onTrack': target == null ? null : left >= target,
      },
      'goals': {
        'items': goals,
        'totalTargetCents': goals.fold(0, (sum, goal) => sum + (goal['targetCents'] as int)),
        'totalSavedCents': goals.fold(0, (sum, goal) => sum + (goal['savedCents'] as int)),
      },
      'subscriptions': {
        'activeCount': (subscriptions['items'] as List).where((item) => item['active'] == true).length,
        'monthlyTotalCents': subscriptions['monthlyTotalCents'],
        'yearlyTotalCents': subscriptions['yearlyTotalCents'],
        'averagePerMonthCents': subscriptions['averagePerMonthCents'],
      },
    };
  }

  FakeResponse _crud(
    List<Map<String, dynamic>> items,
    String method,
    String? id,
    Map<String, dynamic> body, {
    required Map<String, dynamic> Function() list,
    required Map<String, dynamic> Function(Map<String, dynamic> body, Map<String, dynamic>? existing) toItem,
    void Function(Map<String, dynamic> item)? onDelete,
  }) {
    try {
      if (method == 'GET') return FakeResponse(200, list());
      if (method == 'POST') {
        final item = {'id': 'item-${++_counter}', ...toItem(body, null)};
        items.add(item);
        return FakeResponse(201, {'item': item});
      }
      final existing = items.where((item) => item['id'] == id).firstOrNull;
      if (existing == null) return FakeResponse.error(404, 'not_found');
      if (method == 'PUT') {
        existing.addAll(toItem(body, existing));
        return FakeResponse(200, {'item': existing});
      }
      if (method == 'DELETE') {
        items.remove(existing);
        onDelete?.call(existing);
        return const FakeResponse(204);
      }
    } on FakeResponse catch (error) {
      return error;
    }
    return FakeResponse.error(405, 'method_not_allowed');
  }

  String? _nextCharge(Map<String, dynamic> subscription) {
    if (subscription['active'] != true) return null;
    final now = DateTime.parse(today);
    final day = subscription['billingDay'] as int;
    final month = (subscription['billingMonth'] as int?) ?? (day >= now.day ? now.month : now.month + 1);
    var date = DateTime(now.year, month, day);
    if (date.isBefore(now)) date = DateTime(now.year + 1, month, day);
    return '${date.year}-${'${date.month}'.padLeft(2, '0')}-${'${date.day}'.padLeft(2, '0')}';
  }

  Map<String, dynamic> _goalView(String username, Map<String, dynamic> goal) {
    final target = goal['targetCents'] as int;
    final saved = goal['savedCents'] as int;
    final remaining = (target - saved).clamp(0, target);
    final savings = [...savingsOf(username)]
      ..sort((a, b) => (b['effectiveDate'] as String).compareTo(a['effectiveDate'] as String));
    final perMonth = savings.isEmpty ? null : savings.first['amountCents'] as int;
    return {
      ...goal,
      'remainingCents': remaining,
      'progressPercent': saved * 100 ~/ target,
      'completed': remaining == 0,
      'estimatedMonthsLeft': remaining == 0 ? 0 : (perMonth == null ? null : (remaining / perMonth).ceil()),
    };
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
