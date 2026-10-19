import 'dart:io';
import 'dart:ui' as ui;

import 'package:brokenance/core/branding/logo_mark.dart';
import 'package:brokenance/features/auth/view/splash_page.dart';
import 'package:brokenance/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

/// Reads a PNG from assets/brand: its size and its colour at a point (given as 0..1 of the image).
Future<({int width, int height, ui.Color Function(double x, double y) at})> readPng(String name) async {
  final codec = await ui.instantiateImageCodec(File('assets/brand/$name').readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData())!;
  ui.Color at(double x, double y) {
    final px = (x * image.width).round().clamp(0, image.width - 1);
    final py = (y * image.height).round().clamp(0, image.height - 1);
    final i = (py * image.width + px) * 4;
    return ui.Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  }

  return (width: image.width, height: image.height, at: at);
}

void main() {
  group('logo geometry', () {
    test('the letter is a stem and a bowl with a hole', () {
      final letter = LogoGeometry.letter;
      expect(letter.contains(const Offset(330, 250)), isTrue); // top of the stem
      expect(letter.contains(const Offset(330, 800)), isTrue); // bottom of the stem
      expect(letter.contains(const Offset(700, 600)), isTrue); // right side of the bowl
      expect(letter.contains(LogoGeometry.bowlCentre), isFalse); // the hole
      expect(letter.contains(const Offset(900, 200)), isFalse); // outside
    });

    test('the cut splits it in two parts, with a gap between them', () {
      bool inUpper(Offset p) => LogoGeometry.upper.contains(p);
      bool inLower(Offset p) => LogoGeometry.lower.contains(p);

      expect(inUpper(const Offset(330, 250)) && !inLower(const Offset(330, 250)), isTrue);
      expect(inLower(const Offset(330, 800)) && !inUpper(const Offset(330, 800)), isTrue);
      // On the cut line itself: in neither part.
      final onCut = LogoGeometry.cutPoint - LogoGeometry.cutDirection * 170;
      expect(LogoGeometry.letter.contains(onCut), isTrue);
      expect(inUpper(onCut) || inLower(onCut), isFalse);
    });

    test('the letter fits in its box, also when the top part has slid', () {
      final bounds = LogoGeometry.letter.getBounds().expandToInclude(
        LogoGeometry.upper.shift(LogoGeometry.cutDirection * LogoGeometry.slide).getBounds(),
      );
      expect(const Rect.fromLTWH(0, 0, LogoGeometry.box, LogoGeometry.box).contains(bounds.topLeft), isTrue);
      expect(
        const Rect.fromLTWH(0, 0, LogoGeometry.box, LogoGeometry.box).contains(bounds.bottomRight),
        isTrue,
      );
    });
  });

  group('brand images', () {
    test('have the sizes the platforms need', () async {
      for (final (name, size) in [
        ('icon.png', 1024),
        ('icon_foreground.png', 1024),
        ('icon_monochrome.png', 1024),
        ('splash_logo.png', 512),
        ('splash_logo_android12.png', 1152),
      ]) {
        final png = await readPng(name);
        expect((png.width, png.height), (size, size), reason: name);
      }
    });

    testWidgets('the app icon is an opaque blue square with the white letter', (tester) async {
      await tester.runAsync(() async {
        final icon = await readPng('icon.png');
        final corner = icon.at(0.02, 0.02);
        expect(corner.a, 1.0);
        expect(corner.b, greaterThan(corner.r)); // blue
        // The stem of the letter, at 0.8 of the icon: white.
        final stem = icon.at(0.1 + 0.8 * 0.33, 0.1 + 0.8 * 0.75);
        expect((stem.r, stem.g, stem.b), (1.0, 1.0, 1.0));
      });
    });

    testWidgets('the launch logo is transparent around and inside the letter', (tester) async {
      await tester.runAsync(() async {
        final splash = await readPng('splash_logo.png');
        expect(splash.at(0.02, 0.02).a, 0.0);
        expect(splash.at(0.33, 0.75).a, 1.0); // stem
        expect(splash.at(0.5, 0.6).a, 0.0); // the bowl's hole
      });
    });

    testWidgets('the one-colour icon is a solid white letter, the rest see-through', (tester) async {
      await tester.runAsync(() async {
        final mono = await readPng('icon_monochrome.png');
        final stem = mono.at(0.33, 0.75);
        expect(stem.a, 1.0);
        expect((stem.r, stem.g, stem.b), (1.0, 1.0, 1.0));
        expect(mono.at(0.5, 0.6).a, 0.0); // hole
        expect(mono.at(0.9, 0.1).a, 0.0); // outside
      });
    });
  });

  group('splash', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    testWidgets('shows the coin and the name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SplashPage(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(LogoMark), findsOneWidget);
      expect(find.bySemanticsLabel('Brokenance'), findsOneWidget);
      expect(find.text('brokenance'), findsOneWidget);

      // The spinner appears after a couple of seconds and keeps spinning while the app waits.
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('the app shows the logo on the login screen', (tester) async {
      await pumpApp(tester);

      expect(find.byType(LogoMark), findsOneWidget);
      expect(find.text('Log in to continue.'), findsOneWidget);
    });
  });
}
