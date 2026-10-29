#!/usr/bin/env bash
set -euo pipefail

# Regenerates the iOS app icons from icon.svg. Android uses the vector drawable in res/drawable directly.
cd "$(dirname "$0")"
out=../../ios/Runner/Assets.xcassets/AppIcon.appiconset
# iOS has no adaptive-icon safe zone, so crop the margin Android needs.
svg=$(sed 's/viewBox="0 0 108 108"/viewBox="12 12 84 84"/' icon.svg)

jq -r '.images[] | "\(.size) \(.scale) \(.filename)"' "$out/Contents.json" | sort -u |
  while read -r size scale file; do
    px=$(jq -n "${size%x*} * ${scale%x}")
    # App Store rejects icons with an alpha channel.
    rsvg-convert -w "$px" -h "$px" <<< "$svg" | magick - -alpha off "PNG24:$out/$file"
  done
