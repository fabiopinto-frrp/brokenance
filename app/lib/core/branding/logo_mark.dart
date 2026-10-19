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

/// The logo's colours for one mode. Light: a soft white-blue tile and a deep blue letter. Dark:
/// a navy tile and a bright blue letter. Both follow the app's own light and dark themes.
@immutable
class LogoPalette {
  const LogoPalette({
    required this.tileTop,
    required this.tileBottom,
    required this.markTop,
    required this.markBottom,
    required this.tileEdge,
  });

  final Color tileTop;
  final Color tileBottom;
  final Color markTop;
  final Color markBottom;

  /// A hairline around the tile, so a light tile stays visible on a light screen.
  final Color tileEdge;

  static const light = LogoPalette(
    tileTop: Color(0xFFFFFFFF),
    tileBottom: Color(0xFFE4EEFC),
    markTop: Color(0xFF2E8FFF),
    markBottom: Color(0xFF0052C4),
    tileEdge: Color(0xFFDCE4F0),
  );

  static const dark = LogoPalette(
    tileTop: Color(0xFF173A6B),
    tileBottom: Color(0xFF08142A),
    markTop: Color(0xFF8CC8FF),
    markBottom: Color(0xFF2E8FFF),
    tileEdge: Color(0xFF1F3A63),
  );

  static LogoPalette of(Brightness brightness) => brightness == Brightness.dark ? dark : light;
}

/// Paints the letter filling the box it is given. [opening] goes from 0 (the letter looks whole)
/// to 1 (the cut is open and the top part has slid). [color] paints it in one colour (themed
/// icons); without it the letter uses the [palette] gradient.
class LogoMarkPainter extends CustomPainter {
  const LogoMarkPainter({this.opening = 1, this.color, this.palette = LogoPalette.light});

  final double opening;
  final Color? color;
  final LogoPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / LogoGeometry.box;
    canvas
      ..save()
      ..translate((size.width - size.shortestSide) / 2, (size.height - size.shortestSide) / 2)
      ..scale(scale);

    final paint = Paint()..isAntiAlias = true;
    if (color != null) {
      paint.color = color!;
    } else {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.markTop, palette.markBottom],
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoMarkPainter old) =>
      old.opening != opening || old.color != color || old.palette != palette;
}

/// Paints the logo on its tile. [rounded] gives the tile its own rounded corners (inside the app
/// and on launch screens); app icons are full bleed because the phone rounds them itself.
class LogoTilePainter extends CustomPainter {
  const LogoTilePainter({
    this.palette = LogoPalette.light,
    this.opening = 1,
    this.rounded = true,
    this.markFraction = 0.8,
  });

  final LogoPalette palette;
  final double opening;
  final bool rounded;

  /// How much of the tile the letter's box takes.
  final double markFraction;

  /// Corner radius of a rounded tile, as a fraction of its width (like an app icon).
  static const cornerFraction = 0.225;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rounded ? size.shortestSide * cornerFraction : 0),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.tileTop, palette.tileBottom],
        ).createShader(rect),
    );
    if (rounded) {
      canvas.drawRRect(
        shape.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide / 128
          ..color = palette.tileEdge,
      );
    }
    final box = size.shortestSide * markFraction;
    canvas
      ..save()
      ..translate((size.width - box) / 2, (size.height - box) / 2);
    LogoMarkPainter(opening: opening, palette: palette).paint(canvas, Size.square(box));
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoTilePainter old) =>
      old.palette != palette ||
      old.opening != opening ||
      old.rounded != rounded ||
      old.markFraction != markFraction;
}

/// The logo on its tile, [size] logical pixels wide, in the colours of the current mode.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, required this.size, this.opening = 1});

  final double size;
  final double opening;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Semantics(
      image: true,
      label: 'Brokenance',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * LogoTilePainter.cornerFraction),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A2A5C).withValues(alpha: brightness == Brightness.dark ? 0.4 : 0.12),
                blurRadius: size * 0.18,
                offset: Offset(0, size * 0.06),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size.square(size),
            painter: LogoTilePainter(palette: LogoPalette.of(brightness), opening: opening),
          ),
        ),
      ),
    );
  }
}

/// The logo appears whole, then the cut opens and the top slides. Used on the splash screen.
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
