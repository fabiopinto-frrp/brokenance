import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/view/settings_page.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/coming_soon.dart';
import 'app_destinations.dart';

/// All routes. Pages inside the [ShellRoute] share the drawer and the title bar.
///
/// Next part: `/login` and `/register` outside the shell, and a `redirect` that sends users
/// without a session to the login screen.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppDestination.dashboard.path,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppDestination.dashboard.path),
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

Widget _pageFor(AppDestination destination) => switch (destination) {
  AppDestination.settings => const SettingsPage(),
  _ => ComingSoon(icon: destination.selectedIcon),
};

/// Switching sections from the drawer cross-fades the content.
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
