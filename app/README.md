# Brokenance app

Flutter app for Brokenance. It talks to the API in `../backend`.

## Run

Start the API first (`cd ../backend && docker compose up -d`), then:

```sh
flutter pub get
flutter run                      # pick the iOS simulator or the Android emulator
```

The app calls `http://localhost:3000` on the iOS simulator and `http://10.0.2.2:3000` on the Android
emulator. To use another API: `flutter run --dart-define=API_URL=https://api.example.com`.

## Structure

```
lib/
  main.dart, app.dart     start-up and the root widget (providers, theme, language, router)
  core/
    theme/                design tokens (spacing, radii, colours) and the light/dark themes
    l10n/                 LocaleCubit and context.l10n
    router/               routes and the drawer destinations
    network/              ApiClient (Dio), token refresh, ApiException, translated errors
    storage/              secure session storage (tokens), preferences (theme, language)
    format/               Money: cents <-> "12,50 €"
    widgets/              shell (title bar + drawer), drawer, shared widgets
  features/               one folder per feature (bloc, data, view)
  l10n/                   app_en.arb, app_pt.arb (translations) and the generated code
```

Rules:
- No hardcoded text in widgets: add it to both `lib/l10n/app_en.arb` and `app_pt.arb`, then
  `flutter gen-l10n` (also runs on build). Use it with `context.l10n.someKey`.
- Colours come from the theme (`Theme.of(context).colorScheme`, `context.colors`), never raw values.
- Money is always `int` cents. Show it with `Money.format`, read user input with `Money.parse`.
- Material comes from `package:material_ui` (Flutter's new standalone Material package), not
  `package:flutter/material.dart`.

## Tests

```sh
flutter test
flutter analyze
```
