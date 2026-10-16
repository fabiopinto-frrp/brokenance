import 'package:brokenance/core/network/api_client.dart';
import 'package:brokenance/core/storage/session_storage.dart';
import 'package:brokenance/features/auth/bloc/auth_bloc.dart';
import 'package:brokenance/features/auth/data/auth_repository.dart';
import 'package:brokenance/features/profile/bloc/profile_cubit.dart';
import 'package:brokenance/features/profile/data/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 100));

void main() {
  test('loads on login, clears on logout, and never shows the previous user', () async {
    final backend = FakeBackend();
    final api = ApiClient(baseUrl: 'http://api.test', session: MemorySessionStorage(), adapter: backend.api);
    final authRepository = AuthRepository(api);
    final authBloc = AuthBloc(authRepository)..add(const AuthStarted());
    final cubit = ProfileCubit(ProfileRepository(api), authBloc);
    backend
      ..seedUser(username: 'fabio')
      ..seedUser(username: 'ana', password: 'another passphrase');
    await settle();
    expect(cubit.state.status, ProfileStatus.initial);

    authBloc.add(
      AuthLoggedIn(await authRepository.login(username: 'fabio', password: 'correct horse battery')),
    );
    await settle();
    await cubit.setNetWorth(500000);
    expect(cubit.state.profile?.netWorthCents, 500000);

    authBloc.add(const AuthLogoutRequested());
    await settle();
    expect(cubit.state.profile, isNull);

    authBloc.add(AuthLoggedIn(await authRepository.login(username: 'ana', password: 'another passphrase')));
    await settle();
    expect(cubit.state.profile?.username, 'ana');
    expect(cubit.state.profile?.netWorthSet, isFalse);

    await cubit.close();
    await authBloc.close();
  });
}
