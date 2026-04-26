#!/usr/bin/env bash
# Capture App Store screenshots via XCUITest and write PNGs to docs/screenshots/<version>/
#
# Passes TEST_RUNNER_SCREENSHOT_DIR as a build setting so xcodebuild forwards
# it to the XCTest runner process as SCREENSHOT_DIR. ScreenshotTests.snap()
# reads that env var and writes each PNG directly to disk.
#
# Usage:
#   bash scripts/capture-screenshots.sh
#
# Output: docs/screenshots/<MARKETING_VERSION>/*.png (committed to repo)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME=MyPepTracker
TMP_DIR=/tmp/mypeptracker-screenshots

VERSION="$(python3 -c "
import re
with open('$REPO/project.yml') as f:
    text = f.read()
m = re.search(r'MARKETING_VERSION: [\"\\x27]?([^\"\\x27\\n]+)', text)
print(m.group(1).strip())
")"

OUT_DIR="$REPO/docs/screenshots/$VERSION"
mkdir -p "$OUT_DIR"

cd "$REPO"
xcodegen generate --quiet

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "==> Capturing screenshots for v${VERSION} on iPhone 17 Pro Max"
xcodebuild test \
    -project "${SCHEME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
    -only-testing:"${SCHEME}UITests/ScreenshotTests" \
    TEST_RUNNER_SCREENSHOT_DIR="$TMP_DIR"

PNG_COUNT=$(find "$TMP_DIR" -maxdepth 1 -name '[0-9][0-9]-*.png' 2>/dev/null | wc -l | tr -d ' ')
if [[ $PNG_COUNT -eq 0 ]]; then
    echo "ERROR: no screenshots written to $TMP_DIR" >&2
    exit 1
fi

cp "$TMP_DIR"/[0-9][0-9]-*.png "$OUT_DIR/"
echo "==> Captured $PNG_COUNT screenshot(s) → $OUT_DIR"
ls -1 "$OUT_DIR"
