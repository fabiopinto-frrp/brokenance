import 'package:bloc_test/bloc_test.dart';
import 'package:brokenance/core/network/api_client.dart';
import 'package:brokenance/core/network/api_exception.dart';
import 'package:brokenance/core/storage/session_storage.dart';
import 'package:brokenance/features/auth/bloc/auth_bloc.dart';
import 'package:brokenance/features/auth/data/auth_repository.dart';
import 'package:brokenance/features/auth/data/user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';

const fabio = User(id: 'user-fabio', username: 'fabio', firstName: 'Fábio', lastName: 'Pinto');

void main() {
  late FakeBackend backend;
  late MemorySessionStorage session;
  late ApiClient api;
  late AuthRepository repository;

  setUp(() {
    backend = FakeBackend();
    session = MemorySessionStorage();
    api = ApiClient(baseUrl: 'http://api.test', session: session, adapter: backend.api);
    repository = AuthRepository(api);
  });

  Future<void> saveSeededSession() async {
    final tokens = backend.seedUser();
    await session.save(Session(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken));
  }

  group('AuthRepository', () {
    test('login saves the session and returns the user', () async {
      backend.seedUser();

      final user = await repository.login(username: 'fabio', password: 'correct horse battery');

      expect(user, fabio);
      expect(await session.read(), isNotNull);
    });

    test('a failed login saves nothing', () async {
      backend.seedUser();

      await expectLater(
        repository.login(username: 'fabio', password: 'nope'),
        throwsA(isA<ApiException>().having((error) => error.code, 'code', 'invalid_credentials')),
      );
      expect(await session.read(), isNull);
    });

    test('register sends one password and logs in', () async {
      final user = await repository.register(
        firstName: 'Ana',
        lastName: 'Conceição',
        username: 'ana',
        password: 'a long passphrase',
      );

      expect(user.fullName, 'Ana Conceição');
      expect(backend.api.callsTo('/auth/register').single.data, {
        'firstName': 'Ana',
        'lastName': 'Conceição',
        'username': 'ana',
        'password': 'a long passphrase',
      });
      expect(await session.read(), isNotNull);
    });

    test('currentUser is null without a session, and the user with one', () async {
      expect(await repository.currentUser(), isNull);

      await saveSeededSession();
      expect(await repository.currentUser(), fabio);
    });

    test('logout forgets the session and revokes it on the API, even offline', () async {
      await saveSeededSession();
      await repository.logout();
      expect(await session.read(), isNull);
      expect(backend.api.callsTo('/auth/logout'), hasLength(1));

      await saveSeededSession();
      backend.offline = true;
      await repository.logout();
      expect(await session.read(), isNull);
    });
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'starts unauthenticated without a saved session',
      build: () => AuthBloc(repository),
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState.unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'restores a saved session',
      setUp: saveSeededSession,
      build: () => AuthBloc(repository),
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState.authenticated(fabio)],
    );

    blocTest<AuthBloc, AuthState>(
      'stays logged in when the API cannot be reached at start-up',
      setUp: () async {
        await saveSeededSession();
        backend.offline = true;
      },
      build: () => AuthBloc(repository),
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState.authenticated(null)],
    );

    blocTest<AuthBloc, AuthState>(
      'when the session ends on its own, logs out and says why',
      setUp: saveSeededSession,
      build: () => AuthBloc(repository),
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        bloc.add(const AuthStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        backend.expireAllSessions();
        await expectLater(api.get<Object>('/profile'), throwsA(isA<ApiException>()));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const AuthState.authenticated(fabio),
        const AuthState.unauthenticated(sessionExpired: true),
      ],
      verify: (_) async => expect(await session.read(), isNull),
    );

    blocTest<AuthBloc, AuthState>(
      'logs out',
      setUp: saveSeededSession,
      build: () => AuthBloc(repository),
      wait: const Duration(milliseconds: 100),
      seed: () => const AuthState.authenticated(fabio),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthState.unauthenticated()],
    );
  });
}
