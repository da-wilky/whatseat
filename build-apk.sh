#!/usr/bin/env bash
set -euo pipefail

# Builds the signed release APK, arm64 only (every current phone; the other ABIs would triple the size). Same scheme as mobile-bible-app: the keystore lives in
# Infisical (own folder per app) and exists on disk only while Gradle runs.
PROJECT_ID="037393a2-6c04-42e4-b0d6-a16985200880"
ENVIRONMENT="${INFISICAL_ENV:-prod}"
SECRET_PATH="/whatseat"
KEYSTORE="build/tmp/whatseat.p12"
BACKUP_DIR="/mnt/pibackups"

# The target is a mount, which fails more often than the build; fail before building.
if [ ! -d "$BACKUP_DIR" ]; then
  echo "$BACKUP_DIR missing -- is the mount up?" >&2
  exit 1
fi

cd "$(dirname "$0")"

infisical run --projectId "$PROJECT_ID" --env="$ENVIRONMENT" --path "$SECRET_PATH" -- bash -c "
  set -euo pipefail
  trap 'rm -f $KEYSTORE' EXIT
  mkdir -p \$(dirname $KEYSTORE)
  echo \"\$KEYSTORE_BASE64\" | tr -d '[:space:]' | base64 -d > $KEYSTORE
  nix develop path:. -c flutter build apk --release --target-platform android-arm64
"

# Named by version, otherwise every build overwrites the previous one.
VERSION="$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)"
TARGET="$BACKUP_DIR/whatseat-$VERSION.apk"
BUILT="build/app/outputs/flutter-apk/app-release.apk"

# cp, not mv: the SMB mount has no POSIX permissions and mv complains on every run.
cp --no-preserve=mode "$BUILT" "$TARGET"
rm "$BUILT"

echo "APK -> $TARGET"
