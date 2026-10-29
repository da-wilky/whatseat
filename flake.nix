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
      android = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "34" "35" "36" ];
        buildToolsVersions = [ "35.0.0" "36.0.0" ];
        includeNDK = true;
        ndkVersions = [ "28.2.13676358" ];
        cmakeVersions = [ "3.22.1" ];
        includeEmulator = false;
      };
      sdk = "${android.androidsdk}/libexec/android-sdk";
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.flutter pkgs.jdk17 android.platform-tools ];
        ANDROID_HOME = sdk;
        ANDROID_SDK_ROOT = sdk;
        JAVA_HOME = pkgs.jdk17.home;
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/build-tools/36.0.0/aapt2";
      };
    };
}
