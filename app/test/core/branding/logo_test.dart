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
    test('the coin is two halves, on each side of the crack', () {
      const away = LogoGeometry.away;
      final upperSide = away * 100;
      final lowerSide = away * -100;

      expect(LogoGeometry.upper.contains(upperSide), isTrue);
      expect(LogoGeometry.upper.contains(lowerSide), isFalse);
      expect(LogoGeometry.lower.contains(lowerSide), isTrue);
      expect(LogoGeometry.lower.contains(upperSide), isFalse);
    });

    test('together the halves make a coin, and nothing sticks out of it', () {
      const radius = LogoGeometry.radius;
      expect(LogoGeometry.upper.getBounds().width, lessThanOrEqualTo(2 * radius + 0.1));
      expect(LogoGeometry.lower.getBounds().height, lessThanOrEqualTo(2 * radius + 0.1));
      // A point just inside the edge, away from the crack, belongs to one of the two halves.
      for (final angle in [0.0, 1.3, 2.6, 3.9, 5.2]) {
        final point = Offset.fromDirection(angle, radius - 4);
        final inUpper = LogoGeometry.upper.contains(point);
        final inLower = LogoGeometry.lower.contains(point);
        expect(inUpper || inLower, isTrue, reason: 'angle $angle');
        expect(inUpper && inLower, isFalse, reason: 'angle $angle');
      }
      // Outside the coin there is nothing.
      expect(LogoGeometry.upper.contains(const Offset(radius + 10, 0)), isFalse);
    });

    test('the mark always fits in its box', () {
      // Coin plus half of the gap, in every direction, stays inside the box.
      expect(LogoGeometry.radius + LogoGeometry.gap / 2, lessThan(LogoGeometry.extent));
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

    testWidgets('the app icon is an opaque dark square with the coin in the middle', (tester) async {
      await tester.runAsync(() async {
        final icon = await readPng('icon.png');
        expect(icon.at(0.02, 0.02), BrandColors.background); // corner: dark, fully opaque
        final centre = icon.at(0.5, 0.5);
        expect(centre.a, 1.0);
        expect(centre.b, greaterThan(centre.r)); // blue
      });
    });

    testWidgets('the launch logo is transparent around the coin', (tester) async {
      await tester.runAsync(() async {
        final splash = await readPng('splash_logo.png');
        expect(splash.at(0.01, 0.01).a, 0.0);
        expect(splash.at(0.5, 0.35).a, 1.0);
      });
    });

    testWidgets('the one-colour icon is solid white, with the rim and the outside cut out', (tester) async {
      await tester.runAsync(() async {
        final mono = await readPng('icon_monochrome.png');
        expect(mono.at(0.01, 0.01).a, 0.0); // outside
        final body = mono.at(0.4, 0.62); // inside the lower half, between the middle and the rim
        expect(body.a, 1.0);
        expect((body.r, body.g, body.b), (1.0, 1.0, 1.0));
        // Along the lower-left diagonal the rim (a ring) is see-through.
        const scale = 1024 * 0.94 / (2 * LogoGeometry.extent);
        final rim =
            Offset.fromDirection(2.356, LogoGeometry.rimRadius) - LogoGeometry.away * (LogoGeometry.gap / 2);
        final pixel = Offset(0.5, 0.5) + rim * scale / 1024;
        expect(mono.at(pixel.dx, pixel.dy).a, lessThan(0.5));
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
