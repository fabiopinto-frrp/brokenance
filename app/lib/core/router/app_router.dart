import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/register_page.dart';
import '../../features/auth/view/splash_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/coming_soon.dart';
import 'app_destinations.dart';
import 'app_routes.dart';

/// All routes. Pages inside the [ShellRoute] share the drawer and the title bar.
///
/// [authBloc] guards them: while the saved session is checked the splash screen is shown,
/// without a session only login and register are reachable, and with one those two send the
/// user to the dashboard. The router re-checks every time the login state changes.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppDestination.dashboard.path,
    refreshListenable: _StreamListenable(authBloc.stream),
    redirect: (context, state) => authRedirect(authBloc.state.status, state.matchedLocation),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppDestination.dashboard.path),
      GoRoute(path: AppRoutes.splash, pageBuilder: (context, state) => _fade(state, const SplashPage())),
      GoRoute(path: AppRoutes.login, pageBuilder: (context, state) => _fade(state, const LoginPage())),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          for (final destination in AppDestination.values)
            GoRoute(
              path: destination.path,
              pageBuilder: (context, state) => _fade(state, _pageFor(destination)),
            ),
        ],
      ),
    ],
  );
}

/// Where a user with this login status must go from [location]. Null means "stay".
String? authRedirect(AuthStatus status, String location) {
  final isPublic = AppRoutes.public.contains(location);
  final isSplash = location == AppRoutes.splash;
  switch (status) {
    case AuthStatus.unknown:
      return isSplash ? null : AppRoutes.splash;
    case AuthStatus.unauthenticated:
      return isPublic ? null : AppRoutes.login;
    case AuthStatus.authenticated:
      return isPublic || isSplash ? AppDestination.dashboard.path : null;
  }
}

Widget _pageFor(AppDestination destination) => switch (destination) {
  AppDestination.profile => const ProfilePage(),
  AppDestination.settings => const SettingsPage(),
  _ => ComingSoon(icon: destination.selectedIcon),
};

/// Switching sections cross-fades the content.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// Lets go_router listen to a bloc.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
