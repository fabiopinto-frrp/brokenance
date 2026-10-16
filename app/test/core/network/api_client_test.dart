import 'package:brokenance/core/network/api_client.dart';
import 'package:brokenance/core/network/api_exception.dart';
import 'package:brokenance/core/storage/session_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api.dart';

const oldSession = Session(accessToken: 'old-access', refreshToken: 'old-refresh');
const newSession = Session(accessToken: 'new-access', refreshToken: 'new-refresh');

/// A fake API where 'old-access' has expired and 'old-refresh' can be exchanged once.
FakeResponse expiredTokenApi(RequestOptions request) {
  if (request.path == '/auth/refresh') {
    return request.data['refreshToken'] == 'old-refresh'
        ? const FakeResponse(200, {'accessToken': 'new-access', 'refreshToken': 'new-refresh'})
        : FakeResponse.error(401, 'invalid_refresh_token');
  }
  return request.headers['Authorization'] == 'Bearer new-access'
      ? FakeResponse(200, {'path': request.path})
      : FakeResponse.error(401, 'token_expired');
}

void main() {
  late MemorySessionStorage session;

  ApiClient clientFor(FakeApi api) => ApiClient(baseUrl: 'http://api.test', session: session, adapter: api);

  setUp(() => session = MemorySessionStorage(oldSession));

  test('sends the access token', () async {
    final api = FakeApi((request) => const FakeResponse(200, {'ok': true}));
    await clientFor(api).get<Map<String, dynamic>>('/profile');

    expect(api.requests.single.headers['Authorization'], 'Bearer old-access');
  });

  test('does not send a token to login, register and refresh', () async {
    final api = FakeApi((request) => const FakeResponse(200, {'ok': true}));
    await clientFor(api).post<Map<String, dynamic>>('/auth/login', data: {}, authenticated: false);

    expect(api.requests.single.headers['Authorization'], isNull);
  });

  test('refreshes an expired access token and retries the request', () async {
    final api = FakeApi(expiredTokenApi);
    final body = await clientFor(api).get<Map<String, dynamic>>('/profile');

    expect(body, {'path': '/profile'});
    expect(await session.read(), newSession);
    expect(api.callsTo('/auth/refresh'), hasLength(1));
  });

  test('refreshes only once when several requests expire together', () async {
    final api = FakeApi(expiredTokenApi);
    final client = clientFor(api);

    final results = await Future.wait([
      client.get<Map<String, dynamic>>('/profile'),
      client.get<Map<String, dynamic>>('/transactions'),
      client.get<Map<String, dynamic>>('/goals'),
    ]);

    expect(results.map((body) => body['path']), ['/profile', '/transactions', '/goals']);
    expect(api.callsTo('/auth/refresh'), hasLength(1));
  });

  test('ends the session when the refresh token is rejected', () async {
    session = MemorySessionStorage(const Session(accessToken: 'old-access', refreshToken: 'revoked'));
    final api = FakeApi(expiredTokenApi);
    final client = clientFor(api);
    var expired = 0;
    client.sessionExpired.listen((_) => expired++);

    await expectLater(
      client.get<Map<String, dynamic>>('/profile'),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 'token_expired')),
    );
    await Future<void>.delayed(Duration.zero);

    expect(await session.read(), isNull);
    expect(expired, 1);
  });

  test('turns API errors into ApiException with the stable code', () async {
    final api = FakeApi((request) => FakeResponse.error(400, 'date_in_future'));

    await expectLater(
      clientFor(api).post<Map<String, dynamic>>('/transactions', data: {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'date_in_future')
            .having((error) => error.statusCode, 'status', 400),
      ),
    );
  });

  test('reports a server that cannot be reached as network_error', () async {
    final client = ApiClient(baseUrl: 'http://127.0.0.1:9', session: session);

    await expectLater(
      client.get<Object>('/health'),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', ApiException.network)),
    );
  });
}
