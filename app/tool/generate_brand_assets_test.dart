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

Future<void> writePng(String name, int size, void Function(ui.Canvas canvas, double size) draw) async {
  final recorder = ui.PictureRecorder();
  draw(ui.Canvas(recorder), size.toDouble());
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  await File('assets/brand/$name').writeAsBytes(bytes.buffer.asUint8List());
}

/// The mark centred in the image, its box taking [fraction] of it.
void Function(ui.Canvas, double) mark(double fraction, {ui.Color? color}) => (canvas, size) {
  final box = size * fraction;
  canvas.translate((size - box) / 2, (size - box) / 2);
  LogoMarkPainter(color: color).paint(canvas, ui.Size.square(box));
};

String svg() {
  String path(ui.Path p) {
    // Approximate the outline with points every few units, good enough for an SVG preview.
    final buffer = StringBuffer();
    for (final metric in p.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 4) {
        final point = metric.getTangentForOffset(d)!.position;
        buffer.write('${d == 0 ? 'M' : 'L'}${point.dx.toStringAsFixed(1)} ${point.dy.toStringAsFixed(1)}');
      }
      buffer.write('Z');
    }
    return buffer.toString();
  }

  final shift = LogoGeometry.cutDirection * LogoGeometry.slide;
  return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="512" height="512">
  <title>Brokenance</title>
  <defs>
    <linearGradient id="mark" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3D9BFF"/><stop offset="1" stop-color="#0A5FD6"/>
    </linearGradient>
  </defs>
  <path fill="url(#mark)" d="${path(LogoGeometry.lower)}"/>
  <path fill="url(#mark)" d="${path(LogoGeometry.upper.shift(shift))}"/>
</svg>
''';
}

void main() {
  testWidgets('generates the brand images', (tester) async {
    await tester.runAsync(() async {
      Directory('assets/brand').createSync(recursive: true);
      // The full app icon (iOS and old Android): the white letter on the blue tile.
      await writePng(
        'icon.png',
        1024,
        (canvas, size) => const AppIconPainter().paint(canvas, ui.Size.square(size)),
      );
      // Android adaptive icon: the white letter alone; the blue comes from the background colour.
      // flutter_launcher_icons insets it by 16% on every side (the safe zone).
      await writePng('icon_foreground.png', 1024, mark(1, color: Colors.white));
      // Android 13 themed icon: one colour, the system tints it.
      await writePng('icon_monochrome.png', 1024, mark(1, color: Colors.white));
      // Launch screens: the blue letter on a transparent background.
      await writePng('splash_logo.png', 512, mark(1));
      // Android 12 draws the splash logo inside a circle two thirds of the image wide.
      await writePng('splash_logo_android12.png', 1152, mark(0.6));
      File('assets/brand/logo.svg').writeAsStringSync(svg());
    });
  });
}
