/// Routes outside the drawer. The drawer sections are in [AppDestination].
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  /// Pages that are only for users who are not logged in.
  static const public = {login, register};
}
