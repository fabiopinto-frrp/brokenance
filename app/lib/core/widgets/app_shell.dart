import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../router/app_destinations.dart';
import 'app_drawer.dart';

/// The frame around every page inside the app: title bar with the burger button, and the drawer.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final destination = AppDestination.fromLocation(location);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: context.l10n.navOpenMenu,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(destination?.label(context.l10n) ?? context.l10n.appTitle),
      ),
      drawer: AppDrawer(current: destination),
      body: SafeArea(top: false, child: child),
    );
  }
}
