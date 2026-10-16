import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/l10n.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/app_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/profile/bloc/profile_cubit.dart';
import 'features/profile/data/profile_repository.dart';

/// The root widget: provides the shared services and the app-wide blocs, then builds the app.
class BrokenanceApp extends StatelessWidget {
  const BrokenanceApp({super.key, required this.preferences, required this.apiClient});

  final AppPreferences preferences;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider(create: (_) => AuthRepository(apiClient)),
        RepositoryProvider(create: (_) => ProfileRepository(apiClient)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(preferences)),
          BlocProvider(create: (_) => LocaleCubit(preferences)),
          BlocProvider(
            create: (context) => AuthBloc(context.read<AuthRepository>())..add(const AuthStarted()),
          ),
          // App-wide: the drawer shows the balance, and it loads as soon as the user is logged in.
          BlocProvider(
            create: (context) => ProfileCubit(context.read<ProfileRepository>(), context.read<AuthBloc>()),
            lazy: false,
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // Created once, so rebuilding the app (theme or language change) keeps the current page.
  late final GoRouter _router = createRouter(context.read<AuthBloc>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final locale = context.watch<LocaleCubit>().state;

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      // The app's own strings, plus the Material and Cupertino ones (dialogs, date pickers...).
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      routerConfig: _router,
    );
  }
}
