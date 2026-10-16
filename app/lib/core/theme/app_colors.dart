import 'package:material_ui/material_ui.dart';

import 'app_palette.dart';

/// Colours the Material [ColorScheme] does not have a good name for: money going in and out,
/// secondary text and borders. Read them with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surfaceHigh,
    required this.border,
    required this.textSecondary,
    required this.positive,
    required this.negative,
    required this.warning,
  });

  final Color background;
  final Color surfaceHigh;
  final Color border;
  final Color textSecondary;

  /// Money in (income, savings on track).
  final Color positive;

  /// Money out (expenses, charges).
  final Color negative;
  final Color warning;

  static const light = AppColors(
    background: AppPalette.lightBackground,
    surfaceHigh: AppPalette.lightSurfaceHigh,
    border: AppPalette.lightBorder,
    textSecondary: AppPalette.lightTextSecondary,
    positive: AppPalette.lightPositive,
    negative: AppPalette.lightNegative,
    warning: AppPalette.lightWarning,
  );

  static const dark = AppColors(
    background: AppPalette.darkBackground,
    surfaceHigh: AppPalette.darkSurfaceHigh,
    border: AppPalette.darkBorder,
    textSecondary: AppPalette.darkTextSecondary,
    positive: AppPalette.darkPositive,
    negative: AppPalette.darkNegative,
    warning: AppPalette.darkWarning,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surfaceHigh,
    Color? border,
    Color? textSecondary,
    Color? positive,
    Color? negative,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      border: border ?? this.border,
      textSecondary: textSecondary ?? this.textSecondary,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
