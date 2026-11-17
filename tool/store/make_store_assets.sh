#!/usr/bin/env bash
# Rebuilds the Google Play screenshots and feature graphic in build/store/play/.
# Needs ffmpeg (Play wants 24-bit PNGs with no alpha channel).
set -euo pipefail
cd "$(dirname "$0")/../.."
export FLUTTER_ROOT="${FLUTTER_ROOT:-$(dirname "$(dirname "$(command -v flutter)")")}"
[[ -f build/app_icon/full.png ]] || flutter test tool/app_icon/app_icon_test.dart
TZ=Europe/London flutter test tool/store/store_screens_test.dart  # sample user in London
flutter test tool/store/store_frames_test.dart
for f in build/store/play/*.png; do
  ffmpeg -hide_banner -loglevel error -y -i "$f" -pix_fmt rgb24 "${f%.png}.tmp.png"
  mv "${f%.png}.tmp.png" "$f"
done
echo "Play Store assets: build/store/play/"
