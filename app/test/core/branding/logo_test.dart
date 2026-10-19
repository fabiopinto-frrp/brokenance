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
  group('palettes', () {
    test('follow the app mode', () {
      expect(LogoPalette.of(Brightness.light), LogoPalette.light);
      expect(LogoPalette.of(Brightness.dark), LogoPalette.dark);
      // Dark: a dark tile and a brighter letter. Light: a light tile and a deeper letter.
      expect(LogoPalette.dark.tileBottom.computeLuminance(), lessThan(0.05));
      expect(LogoPalette.light.tileTop.computeLuminance(), greaterThan(0.9));
      expect(
        LogoPalette.dark.markBottom.computeLuminance(),
        greaterThan(LogoPalette.light.markBottom.computeLuminance()),
      );
    });
  });

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
        ('icon_light.png', 1024),
        ('icon_dark.png', 1024),
        ('icon_ios_dark.png', 1024),
        ('icon_foreground.png', 1024),
        ('icon_monochrome.png', 1024),
        ('splash_logo.png', 512),
        ('splash_logo_dark.png', 512),
        ('splash_logo_android12.png', 1152),
        ('splash_logo_android12_dark.png', 1152),
      ]) {
        final png = await readPng(name);
        expect((png.width, png.height), (size, size), reason: name);
      }
    });

    testWidgets('the light icon is a light tile with a blue letter, the dark one a navy tile', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // The stem of the letter, whose box takes 0.8 of the icon.
        const stemX = 0.1 + 0.8 * 0.33, stemY = 0.1 + 0.8 * 0.75;

        final light = await readPng('icon_light.png');
        final lightCorner = light.at(0.02, 0.02);
        expect(lightCorner.a, 1.0);
        expect(lightCorner.r, greaterThan(0.9)); // near white
        final lightStem = light.at(stemX, stemY);
        expect(lightStem.b, greaterThan(lightStem.r + 0.4)); // strong blue

        final dark = await readPng('icon_dark.png');
        final darkCorner = dark.at(0.02, 0.02);
        expect(darkCorner.a, 1.0);
        expect(darkCorner.r + darkCorner.g + darkCorner.b, lessThan(0.9)); // navy, dark
        final darkStem = dark.at(stemX, stemY);
        expect(darkStem.b, greaterThan(0.8)); // bright blue
      });
    });

    testWidgets('the iPhone dark icon is transparent around the letter', (tester) async {
      await tester.runAsync(() async {
        final icon = await readPng('icon_ios_dark.png');
        expect(icon.at(0.02, 0.02).a, 0.0);
        expect(icon.at(0.1 + 0.8 * 0.33, 0.1 + 0.8 * 0.75).a, 1.0);
      });
    });

    testWidgets('the launch logos are rounded tiles: transparent corners, opaque inside', (tester) async {
      await tester.runAsync(() async {
        for (final name in ['splash_logo.png', 'splash_logo_dark.png']) {
          final splash = await readPng(name);
          expect(splash.at(0.06, 0.06).a, 0.0, reason: name); // the rounded corner
          expect(splash.at(0.5, 0.6).a, 1.0, reason: name); // the tile shows through the hole
        }
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
