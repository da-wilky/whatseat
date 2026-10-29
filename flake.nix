{
  description = "WhatsEat – Essprotokoll";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
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
          packages = [ pkgs.flutter pkgs.jdk17 pkgs.jq android.androidsdk ];
          ANDROID_HOME = sdk;
          ANDROID_SDK_ROOT = sdk;
          JAVA_HOME = pkgs.jdk17.home;
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/build-tools/36.0.0/aapt2";
          shellHook = ''
            export ANDROID_AVD_HOME="$HOME/.android/avd"
          '';
        };
    in
    {
      devShells.${system} = {
        default = shellFor (composeAndroid { withEmulator = false; });
        emulator = shellFor (composeAndroid { withEmulator = true; });
      };
    };
}
