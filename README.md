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

## Release APK

Same scheme as mobile-bible-app: one keystore per app, stored in Infisical project
`037393a2-6c04-42e4-b0d6-a16985200880`, folder `/whatseat`, under
`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS=whatseat`, `KEY_PASSWORD`
(same value as `KEYSTORE_PASSWORD` – PKCS12 has no separate key password).

Create the keystore once:

```sh
cd "$(mktemp -d)"
nix develop ~/workspace/mine/WhatsEat -c keytool -genkeypair -v -keystore whatseat.p12 -storetype PKCS12 \
  -alias whatseat -keyalg RSA -keysize 4096 -validity 10000
base64 -w0 whatseat.p12
shred -u whatseat.p12
```

Then `./build-apk.sh` builds (arm64 only), signs and copies to `/mnt/pibackups/whatseat-<version>.apk`.
The keystore is unpacked to `build/tmp/` only while Gradle runs. A plain
`flutter build apk --release` yields an **unsigned** APK – on purpose.

Debug builds install as `de.whatseat.whatseat.debug` ("WhatsEat Debug") next to the release app.

## Emulator (headless, over SSH)

```sh
./emulator.sh start        # creates the AVD on first run, returns once booted
nix develop path:. -c flutter run -d emulator-5554
./emulator.sh stop
```

To see and use it from your laptop, forward the emulator's adb port and mirror it with scrcpy:

```sh
ssh -L 5555:localhost:5555 <dev-machine>        # on the laptop
nix shell nixpkgs#android-tools nixpkgs#scrcpy  # on the laptop, second terminal
adb connect localhost:5555 && scrcpy -s localhost:5555
```
