import 'package:material_ui/material_ui.dart';

/// The raw colours of the app. Widgets never use these directly: they read the theme
/// (`Theme.of(context).colorScheme`) or [AppColors] (`context.colors`), so light and dark mode
/// both work.
abstract final class AppPalette {
  // Light: off-white background with white cards (Apple).
  static const lightBackground = Color(0xFFF5F5F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFEDEDF0);
  static const lightBorder = Color(0xFFE3E3E8);
  static const lightText = Color(0xFF1D1D1F);
  static const lightTextSecondary = Color(0xFF6E6E73);
  static const lightAccent = Color(0xFF0071E3);
  static const lightPositive = Color(0xFF1A9E5C);
  static const lightNegative = Color(0xFFD93A3A);
  static const lightWarning = Color(0xFFC77700);

  // Dark: near-black surfaces, not grey (Tesla).
  static const darkBackground = Color(0xFF0A0A0B);
  static const darkSurface = Color(0xFF161618);
  static const darkSurfaceHigh = Color(0xFF212124);
  static const darkBorder = Color(0xFF2A2A2E);
  static const darkText = Color(0xFFF5F5F7);
  static const darkTextSecondary = Color(0xFF8E8E93);
  static const darkAccent = Color(0xFF2E8FFF);
  static const darkPositive = Color(0xFF34C77B);
  static const darkNegative = Color(0xFFFF5A52);
  static const darkWarning = Color(0xFFFFB340);
}
