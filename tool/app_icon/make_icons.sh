#!/usr/bin/env bash
# Resizes the masters from app_icon_test.dart into every Android and iOS launcher-icon slot.
# Needs: macOS sips, ffmpeg (iOS icons must have no alpha channel).
set -euo pipefail
cd "$(dirname "$0")/../.."
src=build/app_icon
[[ -f $src/full.png ]] || { echo "Run: flutter test tool/app_icon/app_icon_test.dart" >&2; exit 1; }

res=android/app/src/main/res
# Legacy icon (48 dp) and adaptive layers (108 dp) per density.
for pair in mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4; do
  d=${pair%%:*}; k=${pair##*:}
  legacy=$(python3 -c "print(round(48*$k))"); layer=$(python3 -c "print(round(108*$k))")
  sips -z "$legacy" "$legacy" $src/full.png --out "$res/mipmap-$d/ic_launcher.png" >/dev/null
  for l in foreground background monochrome; do
    sips -z "$layer" "$layer" "$src/$l.png" --out "$res/mipmap-$d/ic_launcher_$l.png" >/dev/null
  done
done
mkdir -p "$res/mipmap-anydpi-v26"
cat > "$res/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
XML

# iOS: every slot listed in Contents.json, opaque.
set_dir=ios/Runner/Assets.xcassets/AppIcon.appiconset
python3 - "$set_dir/Contents.json" <<'PY' | while read -r file px; do
import json, sys
for i in json.load(open(sys.argv[1]))["images"]:
    side = float(i["size"].split("x")[0]) * int(i["scale"].rstrip("x"))
    print(i["filename"], round(side))
PY
  ffmpeg -hide_banner -loglevel error -y -i $src/full.png -vf "scale=$px:$px:flags=lanczos" \
    -pix_fmt rgb24 "$set_dir/$file"
done
echo "Icons written."
