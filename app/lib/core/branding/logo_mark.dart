import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// The Brokenance mark: a coin (finance) cracked in two (broke), with the top-right half pushed
/// up (it recovers). Everything that shows the logo draws it from here: the in-app logo, the
/// splash animation, and the PNG app icons (see tool/generate_brand_assets_test.dart).
abstract final class LogoGeometry {
  /// The mark is drawn around (0, 0). The coin has this radius...
  static const radius = 300.0;

  /// ...and the mark fits in a square of 2 * [extent] (a little margin around the coin).
  static const extent = 340.0;

  /// The rim ring inside the edge of the coin.
  static const rimRadius = 240.0;
  static const rimWidth = 16.0;

  /// How far apart the two halves end up when the crack is fully open.
  static const gap = 36.0;

  /// Along the crack (top-left to bottom-right) and away from it, towards the upper-right half.
  static const along = Offset(math.sqrt1_2, math.sqrt1_2);
  static const away = Offset(math.sqrt1_2, -math.sqrt1_2);

  // The crack as (position along, sideways wobble) pairs: irregular, like a real fracture.
  static const _crack = [
    (-380.0, 0.0),
    (-215.0, 34.0),
    (-120.0, -26.0),
    (-10.0, 30.0),
    (95.0, -30.0),
    (200.0, 26.0),
    (285.0, -20.0),
    (380.0, 0.0),
  ];

  /// The points of the crack line, from one edge of the coin to the other.
  static final List<Offset> crack = [for (final (t, wobble) in _crack) along * t + away * wobble];

  static final Path _coin = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: radius));

  static Path _half(double side) {
    final far = away * (side * 900);
    final polygon = Path()..addPolygon([...crack, crack.last + far, crack.first + far], true);
    return Path.combine(PathOperation.intersect, _coin, polygon);
  }

  /// The half on the upper-right side of the crack (the one that rises).
  static final Path upper = _half(1);

  /// The half on the lower-left side of the crack.
  static final Path lower = _half(-1);
}

/// Brand colours. The mark is blue on any background: light halves on top, darker below.
abstract final class BrandColors {
  static const background = Color(0xFF0A0A0B);
  static const upperLight = Color(0xFF8CC4FF);
  static const upperDark = Color(0xFF2E8FFF);
  static const lowerLight = Color(0xFF1E7BEF);
  static const lowerDark = Color(0xFF0A4FC0);
}

/// Paints the mark filling the box it is given. [opening] goes from 0 (the coin looks whole) to 1
/// (the crack is fully open). With [monochrome] both halves use that one colour (themed icons).
class LogoMarkPainter extends CustomPainter {
  const LogoMarkPainter({this.opening = 1, this.monochrome});

  final double opening;
  final Color? monochrome;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..translate(size.width / 2, size.height / 2)
      ..scale(size.shortestSide / (2 * LogoGeometry.extent));

    final shift = LogoGeometry.away * (LogoGeometry.gap / 2 * opening);
    final bounds = Rect.fromCircle(center: Offset.zero, radius: LogoGeometry.radius);

    Paint paintFor(Color from, Color to, Alignment begin, Alignment end) => Paint()
      ..isAntiAlias = true
      ..shader = monochrome == null
          ? LinearGradient(begin: begin, end: end, colors: [from, to]).createShader(bounds)
          : null
      ..color = monochrome ?? const Color(0xFFFFFFFF);

    // The rim: a ring inside the edge of each half, which makes the shape read as a coin. In
    // colour it is a lighter line; in one-colour icons it is cut out of the shape.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = LogoGeometry.rimWidth
      ..isAntiAlias = true;
    if (monochrome == null) {
      rim.color = const Color(0x4DFFFFFF);
    } else {
      rim.blendMode = BlendMode.clear;
    }

    void half(Path path, Offset move, Paint fill) {
      canvas
        ..save()
        ..translate(move.dx, move.dy)
        ..drawPath(path, fill)
        ..clipPath(path)
        ..drawCircle(Offset.zero, LogoGeometry.rimRadius, rim)
        ..restore();
    }

    // A layer, so that "cut out" really makes the rim transparent in one-colour icons.
    canvas.saveLayer(Rect.fromCircle(center: Offset.zero, radius: LogoGeometry.extent * 1.2), Paint());
    half(
      LogoGeometry.lower,
      Offset(-shift.dx, -shift.dy),
      paintFor(BrandColors.lowerLight, BrandColors.lowerDark, Alignment.topLeft, Alignment.bottomRight),
    );
    half(
      LogoGeometry.upper,
      shift,
      paintFor(BrandColors.upperLight, BrandColors.upperDark, Alignment.topRight, Alignment.bottomLeft),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoMarkPainter old) => old.opening != opening || old.monochrome != monochrome;
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

/// The mark appears whole and then the coin cracks open. Used on the splash screen.
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
