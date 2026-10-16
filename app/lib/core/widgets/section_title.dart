import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Small uppercase title above a group of settings or cards.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.md),
      child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
