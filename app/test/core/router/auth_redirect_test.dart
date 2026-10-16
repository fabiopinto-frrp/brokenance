import 'package:brokenance/core/router/app_router.dart';
import 'package:brokenance/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows the splash screen while the session is checked', () {
    expect(authRedirect(AuthStatus.unknown, '/dashboard'), '/splash');
    expect(authRedirect(AuthStatus.unknown, '/splash'), isNull);
  });

  test('without a session only login and register are reachable', () {
    expect(authRedirect(AuthStatus.unauthenticated, '/despesas'), '/login');
    expect(authRedirect(AuthStatus.unauthenticated, '/splash'), '/login');
    expect(authRedirect(AuthStatus.unauthenticated, '/login'), isNull);
    expect(authRedirect(AuthStatus.unauthenticated, '/register'), isNull);
  });

  test('with a session, login, register and splash lead to the dashboard', () {
    for (final location in ['/login', '/register', '/splash']) {
      expect(authRedirect(AuthStatus.authenticated, location), '/dashboard');
    }
    expect(authRedirect(AuthStatus.authenticated, '/poupanca'), isNull);
  });
}
