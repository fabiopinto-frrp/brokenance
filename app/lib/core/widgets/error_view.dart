import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../network/api_error_message.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// A whole page that could not load, with a "Try again" button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.colors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              apiErrorMessage(context.l10n, error),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
