import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import '../router/app_destinations.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// The burger menu with every route. Defined once, shown by [AppShell] on every page.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.current});

  final AppDestination? current;

  void _open(BuildContext context, AppDestination destination) {
    Navigator.of(context).pop();
    if (destination != current) context.go(destination.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Drawer(
      width: 300,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
              // The user's name and net worth come here with the profile (next part).
              child: Text(l10n.appTitle, style: theme.textTheme.headlineMedium),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  for (final destination in AppDestination.main)
                    _DrawerItem(
                      destination: destination,
                      selected: destination == current,
                      onTap: () => _open(context, destination),
                    ),
                ],
              ),
            ),
            const Divider(indent: AppSpacing.xl, endIndent: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _DrawerItem(
                destination: AppDestination.settings,
                selected: current == AppDestination.settings,
                onTap: () => _open(context, AppDestination.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.destination, required this.selected, required this.onTap});

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final foreground = selected ? theme.colorScheme.onSurface : colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: colors.surfaceHigh,
        leading: Icon(selected ? destination.selectedIcon : destination.icon, color: foreground),
        title: Text(
          destination.label(context.l10n),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: foreground,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
