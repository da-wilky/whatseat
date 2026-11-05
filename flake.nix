{
  description = "WhatsEat – Essprotokoll";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
      # Must cover flutter_tools defaults and what plugins compile against, or Gradle tries to download into the read-only SDK.
      # The emulator and its system image are a multi-GB download, so they sit in a separate shell.
      composeAndroid = { withEmulator }: pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "34" "35" "36" ];
        buildToolsVersions = [ "35.0.0" "36.0.0" ];
        includeNDK = true;
        ndkVersions = [ "28.2.13676358" ];
        cmakeVersions = [ "3.22.1" ];
        includeEmulator = withEmulator;
        includeSystemImages = withEmulator;
        systemImageTypes = [ "google_apis_playstore" ];
        abiVersions = [ "x86_64" ];
      };
      shellFor = android:
        let sdk = "${android.androidsdk}/libexec/android-sdk";
        in pkgs.mkShell {
          packages = [ pkgs.flutter pkgs.jdk17 pkgs.jq android.androidsdk pkgs.go pkgs.gopls pkgs.delve ];
          ANDROID_HOME = sdk;
          ANDROID_SDK_ROOT = sdk;
          JAVA_HOME = pkgs.jdk17.home;
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/build-tools/36.0.0/aapt2";
          shellHook = ''
            export ANDROID_AVD_HOME="$HOME/.android/avd"
          '';
        };
      emulatorAndroid = composeAndroid { withEmulator = true; };
      emulatorSdk = "${emulatorAndroid.androidsdk}/libexec/android-sdk";
      # Headless, for working over SSH: `nix run path:.#emulator [-- stop]`.
      emulatorApp = pkgs.writeShellApplication {
        name = "whatseat-emulator";
        runtimeInputs = [ emulatorAndroid.androidsdk pkgs.jdk17 pkgs.procps pkgs.util-linux pkgs.gawk pkgs.gnugrep ];
        text = ''
          export ANDROID_HOME=${emulatorSdk} ANDROID_SDK_ROOT=${emulatorSdk} JAVA_HOME=${pkgs.jdk17.home}
          export ANDROID_AVD_HOME="$HOME/.android/avd"
          avd=whatseat
          log="''${XDG_STATE_HOME:-$HOME/.local/state}/whatseat-emulator.log"

          case "''${1:-start}" in
            start)
              if ! pgrep -u "$USER" -f "qemu-system.*-avd $avd" > /dev/null; then
                if ! avdmanager list avd -c | grep -qx "$avd"; then
                  echo no | avdmanager create avd -n "$avd" -k "system-images;android-36;google_apis_playstore;x86_64" -d pixel_7
                fi
                mkdir -p "$(dirname "$log")"
                # setsid: keeps running after the SSH session ends.
                setsid emulator -avd "$avd" -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect \
                  > "$log" 2>&1 < /dev/null &
                echo "booting, log: $log"
              fi
              # shellcheck disable=SC2016 # expanded on the device
              adb wait-for-device shell 'while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 1; done'
              host=$(< /proc/sys/kernel/hostname)
              cat <<EOF

          Emulator running as emulator-5554.

          On this machine:
            nix develop path:. -c flutter run -d emulator-5554

          On another machine, to see and use it:
            ssh -N -L 5555:localhost:5555 $USER@$host
            # second terminal:
            nix shell nixpkgs#android-tools nixpkgs#scrcpy -c sh -c 'adb connect localhost:5555 && scrcpy -s localhost:5555'

          Stop with: nix run path:.#emulator -- stop
          EOF
              ;;
            stop)
              for serial in $(adb devices | awk '/^emulator-/ {print $1}'); do
                adb -s "$serial" emu kill
              done
              ;;
            *)
              echo "usage: whatseat-emulator [start|stop]" >&2
              exit 1
              ;;
          esac
        '';
      };
    in
    {
      devShells.${system} = {
        default = shellFor (composeAndroid { withEmulator = false; });
        emulator = shellFor emulatorAndroid;
      };
      packages.${system}.whatseat-server = pkgs.buildGoModule {
        pname = "whatseat-server";
        version = "0.2.0";
        src = ./server;
        vendorHash = "sha256-zafxVNQsomtOwZ3RCyAeIgBg4Aj4Pf6yD3qZt6umd+Y=";
        meta.mainProgram = "whatseat-server";
      };
      nixosModules.whatseat-server = import ./server/module.nix { inherit self; };
      apps.${system}.emulator = {
        type = "app";
        program = "${emulatorApp}/bin/whatseat-emulator";
        meta.description = "Headless Android emulator for testing over SSH";
      };
    };
}
