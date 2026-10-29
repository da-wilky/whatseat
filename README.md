# WhatsEat

Offline food diary (Essprotokoll) for therapy – Flutter, Android + iOS.

```sh
nix develop path:.                   # Flutter, JDK 17, Android SDK
flutter pub run build_runner build   # after changing lib/data/database.dart
flutter run                          # or: flutter build apk
flutter analyze && flutter test
```

- Storage: drift on SQLite3MultipleCiphers (`hooks.user_defines` in pubspec), key in Keystore/Keychain.
- Strings: `lib/l10n/app_{de,en}.arb` (German is the template).
- iOS builds need macOS + Xcode.
