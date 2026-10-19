// Regenerates the brand images in assets/brand from the logo painter:
//
//   flutter test tool/generate_brand_assets_test.dart
//
// Then regenerate the platform icons and launch screens:
//
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// This is not part of the normal test run (it lives in tool/, not test/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:brokenance/core/branding/logo_mark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Colors;

Future<void> writePng(
  String name, {
  required int size,
  required double markFraction,
  ui.Color? background,
  ui.Color? monochrome,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (background != null) {
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), ui.Paint()..color = background);
  }
  final box = size * markFraction;
  canvas.translate((size - box) / 2, (size - box) / 2);
  LogoMarkPainter(monochrome: monochrome).paint(canvas, ui.Size.square(box));

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  await File('assets/brand/$name').writeAsBytes(bytes.buffer.asUint8List());
}

String svg() {
  String points(List<ui.Offset> list) =>
      list.map((p) => '${p.dx.toStringAsFixed(1)},${p.dy.toStringAsFixed(1)}').join(' ');
  final crack = LogoGeometry.crack;
  const gap = LogoGeometry.gap / 2;
  final far = LogoGeometry.away * 900;
  String clipPoints(double side) {
    final f = far * side;
    return points([...crack, crack.last + f, crack.first + f]);
  }

  final shift = LogoGeometry.away * gap;
  String half(String id, double side, ui.Offset move, String from, String to) =>
      '''
  <clipPath id="clip-$id"><polygon points="${clipPoints(side)}"/></clipPath>
  <linearGradient id="fill-$id" x1="${side > 0 ? 1 : 0}" y1="0" x2="${side > 0 ? 0 : 1}" y2="1">
    <stop offset="0" stop-color="$from"/><stop offset="1" stop-color="$to"/>
  </linearGradient>
  <g transform="translate(${move.dx.toStringAsFixed(1)} ${move.dy.toStringAsFixed(1)})" clip-path="url(#clip-$id)">
    <circle r="${LogoGeometry.radius}" fill="url(#fill-$id)"/>
    <circle r="${LogoGeometry.rimRadius}" fill="none" stroke="#fff" stroke-opacity="0.3" stroke-width="${LogoGeometry.rimWidth}"/>
  </g>''';
  return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-340 -340 680 680" width="512" height="512">
  <title>Brokenance</title>
${half('lower', -1, shift * -1, '#1E7BEF', '#0A4FC0')}
${half('upper', 1, shift, '#8CC4FF', '#2E8FFF')}
</svg>
''';
}

void main() {
  testWidgets('generates the brand images', (tester) async {
    await tester.runAsync(() async {
      Directory('assets/brand').createSync(recursive: true);
      // The full app icon (iOS and old Android): dark square with the mark.
      await writePng('icon.png', size: 1024, markFraction: 0.66, background: BrandColors.background);
      // Android adaptive icon: the mark alone over a dark background. flutter_launcher_icons insets it
      // by 16% on every side, which keeps the coin inside the safe zone the phone never crops.
      await writePng('icon_foreground.png', size: 1024, markFraction: 0.94);
      // Android 13 themed icon: one colour, the system tints it.
      await writePng('icon_monochrome.png', size: 1024, markFraction: 0.94, monochrome: Colors.white);
      // Launch screens: the mark alone on a transparent background.
      await writePng('splash_logo.png', size: 512, markFraction: 0.94);
      // Android 12 draws the splash logo inside a circle two thirds of the image wide.
      await writePng('splash_logo_android12.png', size: 1152, markFraction: 0.62);
      File('assets/brand/logo.svg').writeAsStringSync(svg());
    });
  });
}
