import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Placeholder for screens that are not built yet.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.slow,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(color: context.colors.surfaceHigh, shape: BoxShape.circle),
                child: Icon(icon, size: 36, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(context.l10n.comingSoonTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.comingSoonMessage,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
