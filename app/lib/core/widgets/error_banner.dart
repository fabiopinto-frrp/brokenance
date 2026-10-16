import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// A short message above a form: an error, or a notice like "your session has expired".
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.icon = Icons.error_outline_rounded});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.negative;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.control),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
