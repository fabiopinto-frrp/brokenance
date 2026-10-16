import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_tokens.dart';

/// Light and dark themes. Material 3 underneath, but every component is styled so the app
/// looks minimal (Apple / Tesla): flat surfaces, soft borders, large radii, no tinted elevation.
abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    colors: AppColors.light,
    scheme: const ColorScheme.light(
      primary: AppPalette.lightAccent,
      onPrimary: Colors.white,
      secondary: AppPalette.lightAccent,
      onSecondary: Colors.white,
      surface: AppPalette.lightSurface,
      onSurface: AppPalette.lightText,
      onSurfaceVariant: AppPalette.lightTextSecondary,
      surfaceContainerHighest: AppPalette.lightSurfaceHigh,
      outline: AppPalette.lightBorder,
      outlineVariant: AppPalette.lightBorder,
      error: AppPalette.lightNegative,
      onError: Colors.white,
    ),
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    scheme: const ColorScheme.dark(
      primary: AppPalette.darkAccent,
      onPrimary: Colors.white,
      secondary: AppPalette.darkAccent,
      onSecondary: Colors.white,
      surface: AppPalette.darkSurface,
      onSurface: AppPalette.darkText,
      onSurfaceVariant: AppPalette.darkTextSecondary,
      surfaceContainerHighest: AppPalette.darkSurfaceHigh,
      outline: AppPalette.darkBorder,
      outlineVariant: AppPalette.darkBorder,
      error: AppPalette.darkNegative,
      onError: Colors.white,
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required AppColors colors,
  }) {
    final textTheme = _textTheme(scheme.onSurface, colors.textSecondary);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      textTheme: textTheme,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          // Light mode relies on the white card over the off-white page, dark mode on a border.
          side: isDark ? BorderSide(color: colors.border) : BorderSide.none,
        ),
      ),
      drawerTheme: DrawerThemeData(
        // In dark mode the drawer is one step lighter than the page, so its edge is visible.
        backgroundColor: isDark ? scheme.surface : colors.background,
        scrimColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.35),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.xl)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        iconColor: colors.textSecondary,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        border: const OutlineInputBorder(borderRadius: AppRadius.control, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.control, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
        hintStyle: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: colors.border),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: colors.surfaceHigh,
          selectedBackgroundColor: scheme.surface,
          selectedForegroundColor: scheme.onSurface,
          foregroundColor: colors.textSecondary,
          side: BorderSide(color: colors.border),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.surface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Inter, with tighter letter spacing on the large sizes (like Apple's display type).
  static TextTheme _textTheme(Color text, Color secondary) {
    final base = GoogleFonts.interTextTheme();
    TextStyle? style(TextStyle? s, double size, FontWeight weight, {double spacing = 0, Color? color}) =>
        s?.copyWith(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: color ?? text,
          height: 1.25,
        );

    return base.copyWith(
      displayLarge: style(base.displayLarge, 44, FontWeight.w700, spacing: -1.2),
      displayMedium: style(base.displayMedium, 36, FontWeight.w700, spacing: -1),
      displaySmall: style(base.displaySmall, 30, FontWeight.w700, spacing: -0.8),
      headlineLarge: style(base.headlineLarge, 28, FontWeight.w700, spacing: -0.6),
      headlineMedium: style(base.headlineMedium, 24, FontWeight.w700, spacing: -0.4),
      headlineSmall: style(base.headlineSmall, 20, FontWeight.w600, spacing: -0.3),
      titleLarge: style(base.titleLarge, 20, FontWeight.w600, spacing: -0.3),
      titleMedium: style(base.titleMedium, 16, FontWeight.w600, spacing: -0.1),
      titleSmall: style(base.titleSmall, 14, FontWeight.w600),
      bodyLarge: style(base.bodyLarge, 16, FontWeight.w400),
      bodyMedium: style(base.bodyMedium, 14, FontWeight.w400, color: secondary),
      bodySmall: style(base.bodySmall, 12, FontWeight.w400, color: secondary),
      labelLarge: style(base.labelLarge, 15, FontWeight.w600),
      labelMedium: style(base.labelMedium, 13, FontWeight.w500, color: secondary),
      labelSmall: style(base.labelSmall, 11, FontWeight.w500, spacing: 0.4, color: secondary),
    );
  }
}
