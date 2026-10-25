#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/assets/brand/csc-icon.png"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT

# Apple App Store icons must be opaque. Flatten the official transparent mark
# onto white before producing the per-platform raster sizes.
sips -s format jpeg -s formatOptions 100 "$SOURCE" --out "$TEMP/brand.jpg" >/dev/null
sips -s format png "$TEMP/brand.jpg" --out "$TEMP/brand.png" >/dev/null

python3 - "$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" <<'PY' |
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text())
for image in manifest["images"]:
    if "filename" not in image:
        continue
    pixels = round(float(image["size"].split("x")[0]) * float(image["scale"].removesuffix("x")))
    print(f"{image['filename']}|{pixels}")
PY
while IFS='|' read -r filename pixels; do
  sips -z "$pixels" "$pixels" "$TEMP/brand.png" \
    --out "$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename" >/dev/null
done

for size in 16 32 64 128 256 512 1024; do
  sips -z "$size" "$size" "$TEMP/brand.png" \
    --out "$ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png" >/dev/null
done

for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  case "$density" in
    mdpi) pixels=48 ;;
    hdpi) pixels=72 ;;
    xhdpi) pixels=96 ;;
    xxhdpi) pixels=144 ;;
    xxxhdpi) pixels=192 ;;
  esac
  sips -z "$pixels" "$pixels" "$TEMP/brand.png" \
    --out "$ROOT/android/app/src/main/res/mipmap-$density/ic_launcher.png" >/dev/null
done

for size in 16 32 48 64 128 256; do
  sips -z "$size" "$size" "$TEMP/brand.png" --out "$TEMP/icon-$size.png" >/dev/null
done

python3 - "$TEMP" "$ROOT/windows/runner/resources/app_icon.ico" <<'PY'
import struct
import sys
from pathlib import Path

directory = Path(sys.argv[1])
sizes = (16, 32, 48, 64, 128, 256)
images = [(size, (directory / f"icon-{size}.png").read_bytes()) for size in sizes]
offset = 6 + 16 * len(images)
entries = []
payload = []
for size, data in images:
    dimension = 0 if size == 256 else size
    entries.append(struct.pack("<BBBBHHII", dimension, dimension, 0, 0, 1, 32, len(data), offset))
    payload.append(data)
    offset += len(data)
Path(sys.argv[2]).write_bytes(struct.pack("<HHH", 0, 1, len(images)) + b"".join(entries) + b"".join(payload))
PY

echo "Generated iOS, macOS, Android, and Windows icons from assets/brand/csc-icon.png"
