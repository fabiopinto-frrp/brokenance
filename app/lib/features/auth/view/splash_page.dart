import 'package:material_ui/material_ui.dart';

import '../../../core/branding/logo_mark.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';

/// Shown while the saved session is checked. It continues the launch screen (the same coin, the
/// same size): the coin cracks open, then the name fades in. The spinner only appears when the
/// wait is long, for example while a free server wakes up.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  /// The coin's width on screen, matching the native launch screen.
  static const logoSize = 128.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedLogoMark(size: logoSize),
            const SizedBox(height: AppSpacing.lg),
            _FadeIn(
              delay: const Duration(milliseconds: 500),
              child: Text(
                // The name is a brand mark: always lowercase, never translated.
                context.l10n.appTitle.toLowerCase(),
                style: theme.textTheme.displaySmall?.copyWith(letterSpacing: -1.4),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _FadeIn(
              delay: Duration(seconds: 2),
              child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades its child in after [delay].
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const fade = AppDurations.slow;
    final total = delay + fade;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: Curves.easeOut),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}
