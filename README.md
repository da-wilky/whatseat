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
nix run path:.#emulator           # creates the AVD on first run, returns once booted, prints how to connect
nix develop path:. -c flutter run -d emulator-5554
nix run path:.#emulator -- stop
```

## Backup server

`server/` is a small Go service that stores the app's encrypted backups (stdlib + pure-Go SQLite).
Accounts exist only as an ID and token hash, both derived in the app from the recovery code;
the server never gets anything that decrypts.

```sh
cd server && nix shell nixpkgs#go -c go test ./...
nix build path:.#whatseat-server
```

NixOS (it serves plain HTTP on localhost; the app requires HTTPS):

```nix
{
  imports = [ whatseat.nixosModules.whatseat-server ];
  services.whatseat-server = {
    enable = true;
    publicUrl = "https://backup.example.org";
    inviteOnly = true;      # default: anyone can register, up to maxAccounts (100); invites ignore that limit
    inactiveDays = 365;     # accounts without login are deleted with their backups; 0 = never
    purgeInterval = "24h";  # how often that cleanup runs (in-process, also at startup)
  };
  services.nginx.virtualHosts."backup.example.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:8470";
    extraConfig = "client_max_body_size 6m;";
  };
}
```

Invites: `sudo whatseat-server-invite [validity]` (default `3d`; e.g. `30m`, `1h`, `365d`) prints a single-use code and, with
`publicUrl` set, a link that fills in server and invite when pasted in the app.
Outside NixOS every flag is also an env var: `WHATSEAT_INVITE_ONLY=true`, `WHATSEAT_INACTIVE_DAYS=365`, ….

After changing `server/go.mod`, update `vendorHash` in `flake.nix`.
