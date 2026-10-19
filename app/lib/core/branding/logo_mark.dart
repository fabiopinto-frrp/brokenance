import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// The Brokenance mark: a bold geometric "b" sliced once on a diagonal, the top part shifted
/// along the cut (broke, but still moving up). Everything that shows the logo draws it from here:
/// the in-app logo, the splash animation and the PNG icons (tool/generate_brand_assets_test.dart).
abstract final class LogoGeometry {
  /// The mark is drawn in a 1000 x 1000 box; the letter is centred in it.
  static const box = 1000.0;

  /// Stroke width of the stem and the bowl.
  static const stroke = 140.0;

  /// The stem: from the top of the letter to its baseline.
  static const stem = Rect.fromLTWH(260, 160, stroke, 680);

  /// The bowl: a ring sitting on the baseline, overlapping the stem.
  static const bowlCentre = Offset(500, 600);
  static const bowlRadius = 240.0;

  /// The cut: a straight line through the letter, rising to the right.
  static const cutPoint = Offset(500, 560);
  static final cutDirection = Offset.fromDirection(-25 * math.pi / 180);

  /// Width of the gap the cut leaves, and how far the top part slides along it when open.
  static const gap = 26.0;
  static const slide = 26.0;

  static final Path letter = () {
    final stemPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          stem,
          topLeft: const Radius.circular(stroke / 2),
          topRight: const Radius.circular(stroke / 2),
        ),
      );
    final outer = Path()..addOval(Rect.fromCircle(center: bowlCentre, radius: bowlRadius));
    final inner = Path()..addOval(Rect.fromCircle(center: bowlCentre, radius: bowlRadius - stroke));
    final bowl = Path.combine(PathOperation.difference, outer, inner);
    return Path.combine(PathOperation.union, stemPath, bowl);
  }();

  /// The side of the cut above it ([side] 1) or below it ([side] -1), minus half the gap.
  static Path _side(double side) {
    final normal = Offset(cutDirection.dy, -cutDirection.dx) * side; // points away from the cut
    final start = cutPoint - cutDirection * 2000 + normal * (gap / 2);
    final end = cutPoint + cutDirection * 2000 + normal * (gap / 2);
    return Path()..addPolygon([start, end, end + normal * 3000, start + normal * 3000], true);
  }

  /// The part of the letter above the cut (the one that slides).
  static final Path upper = Path.combine(PathOperation.intersect, letter, _side(1));

  /// The part of the letter below the cut.
  static final Path lower = Path.combine(PathOperation.intersect, letter, _side(-1));
}

/// Brand colours.
abstract final class BrandColors {
  /// The app icon's tile, top-left to bottom-right.
  static const tileLight = Color(0xFF3D9BFF);
  static const tileDark = Color(0xFF0A4FC0);

  /// The letter on light or dark screens, top to bottom.
  static const markLight = Color(0xFF3D9BFF);
  static const markDark = Color(0xFF0A5FD6);

  /// Background of the Android adaptive icon (a flat colour).
  static const iconBackground = Color(0xFF1A6FE0);
}

/// Paints the mark filling the box it is given. [opening] goes from 0 (the letter looks whole)
/// to 1 (the cut is open and the top part has slid). [color] paints it in one colour (white on
/// the app icon, themed icons); without it the letter uses the brand gradient.
class LogoMarkPainter extends CustomPainter {
  const LogoMarkPainter({this.opening = 1, this.color});

  final double opening;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / LogoGeometry.box;
    canvas
      ..translate((size.width - size.shortestSide) / 2, (size.height - size.shortestSide) / 2)
      ..scale(scale);

    final paint = Paint()..isAntiAlias = true;
    if (color != null) {
      paint.color = color!;
    } else {
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [BrandColors.markLight, BrandColors.markDark],
      ).createShader(const Rect.fromLTWH(0, 150, LogoGeometry.box, 700));
    }

    // While closed, the gap is hidden by drawing the whole letter; it fades into the cut letter.
    final shift = LogoGeometry.cutDirection * (LogoGeometry.slide * opening);
    canvas.drawPath(LogoGeometry.lower, paint);
    canvas.drawPath(LogoGeometry.upper.shift(shift), paint);
    if (opening < 1) {
      final whole = Paint()
        ..shader = paint.shader
        ..color = paint.color.withValues(alpha: (1 - opening).clamp(0, 1) * paint.color.a);
      canvas.drawPath(LogoGeometry.letter, whole);
    }
  }

  @override
  bool shouldRepaint(LogoMarkPainter old) => old.opening != opening || old.color != color;
}

/// Paints the app icon: the white letter on the blue tile, full bleed (the platforms round it).
class AppIconPainter extends CustomPainter {
  const AppIconPainter({this.markFraction = 0.8});

  /// How much of the icon the letter's box takes.
  final double markFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.tileLight, BrandColors.tileDark],
        ).createShader(rect),
    );
    final box = size.shortestSide * markFraction;
    canvas.translate((size.width - box) / 2, (size.height - box) / 2);
    const LogoMarkPainter(color: Color(0xFFFFFFFF)).paint(canvas, Size.square(box));
  }

  @override
  bool shouldRepaint(AppIconPainter old) => old.markFraction != markFraction;
}

/// The mark as a widget, [size] logical pixels wide and tall.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, required this.size, this.opening = 1});

  final double size;
  final double opening;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Brokenance',
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: LogoMarkPainter(opening: opening),
        ),
      ),
    );
  }
}

/// The letter appears whole, then the cut opens and the top slides. Used on the splash screen.
class AnimatedLogoMark extends StatelessWidget {
  const AnimatedLogoMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow * 2.5,
      curve: const Interval(0.3, 1, curve: Curves.easeOutBack),
      builder: (context, opening, _) => LogoMark(size: size, opening: opening),
    );
  }
}
