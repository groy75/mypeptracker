#!/usr/bin/env bash
# ship-screenshots.sh — capture + upload App Store screenshots for the current version,
# then (optionally) submit the version for App Store review.
#
# Usage:
#   bash scripts/ship-screenshots.sh               # capture, upload, don't submit
#   bash scripts/ship-screenshots.sh --submit       # capture, upload, and submit for review
#
# Prerequisites:
#   • ~/.cache/claude-code/peptide-tracker.env      (ASC creds)
#   • xcodegen, xcodebuild, python3, pillow
#
# What it does:
#   1. Reads MARKETING_VERSION from project.yml
#   2. Captures iPhone 6.7" screenshots via XCUITest → docs/screenshots/<ver>/
#   3. Generates iPad Pro 13" screenshots by letterboxing onto a black canvas
#   4. Uploads both sets to the matching ASC version, replacing any existing sets
#   5. If --submit: attaches build, patches whatsNew, creates reviewSubmission, submits
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

SUBMIT=0
for arg in "$@"; do [[ "$arg" == "--submit" ]] && SUBMIT=1; done

# ── read version ──────────────────────────────────────────────────────────────
VERSION="$(python3 -c "
import re
with open('$REPO/project.yml') as f: text = f.read()
m = re.search(r'MARKETING_VERSION:\s*[\"\\x27]?([^\"\\x27\\n]+)', text)
print(m.group(1).strip())
")"
BUILD="$(python3 -c "
import re
with open('$REPO/project.yml') as f: text = f.read()
m = re.search(r'CURRENT_PROJECT_VERSION:\s*[\"\\x27]?([^\"\\x27\\n]+)', text)
print(m.group(1).strip())
")"
echo "==> version $VERSION  build $BUILD"

# ── capture iPhone screenshots ────────────────────────────────────────────────
IPHONE_DIR="$REPO/docs/screenshots/$VERSION"
mkdir -p "$IPHONE_DIR"
TMP_DIR=/tmp/mypeptracker-screenshots-$$
rm -rf "$TMP_DIR"; mkdir -p "$TMP_DIR"

cd "$REPO"
xcodegen generate --quiet

echo "==> capturing iPhone 6.7\" screenshots …"
xcodebuild test \
    -project MyPepTracker.xcodeproj \
    -scheme MyPepTracker \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
    -only-testing:MyPepTrackerUITests/ScreenshotTests \
    TEST_RUNNER_SCREENSHOT_DIR="$TMP_DIR" \
    2>&1 | grep -E "Test Case|passed|failed|Executed"

PNG_COUNT=$(find "$TMP_DIR" -maxdepth 1 -name '[0-9][0-9]-*.png' 2>/dev/null | wc -l | tr -d ' ')
[[ $PNG_COUNT -eq 0 ]] && { echo "ERROR: no screenshots in $TMP_DIR" >&2; exit 1; }
cp "$TMP_DIR"/[0-9][0-9]-*.png "$IPHONE_DIR/"
echo "==> $PNG_COUNT iPhone screenshots → $IPHONE_DIR"

# ── generate iPad screenshots (letterbox) ─────────────────────────────────────
IPAD_DIR="$REPO/docs/screenshots/$VERSION-ipad"
mkdir -p "$IPAD_DIR"
python3 - "$IPHONE_DIR" "$IPAD_DIR" <<'PYEOF'
import sys
from PIL import Image
import os

src_dir, dst_dir = sys.argv[1], sys.argv[2]
IPAD_W, IPAD_H = 2064, 2752
shots = sorted(f for f in os.listdir(src_dir) if f.endswith(".png") and f[:2].isdigit())
for fn in shots:
    img = Image.open(os.path.join(src_dir, fn)).convert("RGBA")
    scale = IPAD_H / img.height
    sw = int(img.width * scale)
    scaled = img.resize((sw, IPAD_H), Image.LANCZOS)
    canvas = Image.new("RGBA", (IPAD_W, IPAD_H), (0, 0, 0, 255))
    canvas.paste(scaled, ((IPAD_W - sw) // 2, 0))
    canvas.convert("RGB").save(os.path.join(dst_dir, fn), "PNG", optimize=True)
    print(f"  {fn}")
print(f"iPad screenshots generated in {dst_dir}")
PYEOF

# ── upload to ASC ──────────────────────────────────────────────────────────────
source ~/.cache/claude-code/peptide-tracker.env

python3 - "$VERSION" "$IPHONE_DIR" "$IPAD_DIR" \
    "$ASC_API_KEY_ID" "$ASC_API_ISSUER_ID" "$ASC_API_KEY_P8" "$APP_STORE_ADAM_ID" \
    "$SUBMIT" <<'PYEOF'
import base64, hashlib, json, os, sys, time, urllib.error, urllib.request
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils

VERSION, IPHONE_DIR, IPAD_DIR, KEY_ID, ISSUER_ID, P8_STR, ADAM_ID, DO_SUBMIT = sys.argv[1:]
DO_SUBMIT = DO_SUBMIT == "1"
P8 = P8_STR.encode()

pk = serialization.load_pem_private_key(P8, password=None)
def jwt():
    now = int(time.time())
    h = base64.urlsafe_b64encode(json.dumps({"alg":"ES256","kid":KEY_ID,"typ":"JWT"}).encode()).rstrip(b"=").decode()
    p = base64.urlsafe_b64encode(json.dumps({"iss":ISSUER_ID,"iat":now,"exp":now+1000,"aud":"appstoreconnect-v1"}).encode()).rstrip(b"=").decode()
    msg = f"{h}.{p}".encode()
    sig = pk.sign(msg, ec.ECDSA(hashes.SHA256()))
    r, s = utils.decode_dss_signature(sig)
    return f"{h}.{p}.{base64.urlsafe_b64encode(r.to_bytes(32,'big')+s.to_bytes(32,'big')).rstrip(b'=').decode()}"
BASE = "https://api.appstoreconnect.apple.com"
def api(method, path, body=None):
    url = BASE + path
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, headers={"Authorization":f"Bearer {jwt()}","Content-Type":"application/json"}, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        if e.code == 204: return {}
        raise RuntimeError(f"{method} {url} -> {e.code}: {e.read().decode()[:500]}")

# find version
print(f"looking up {VERSION} …")
resp = api("GET", f"/v1/apps/{ADAM_ID}/appStoreVersions?filter[versionString]={VERSION}&filter[platform]=IOS&limit=5")
versions = resp.get("data", [])
if not versions: sys.exit(f"ERROR: no {VERSION} version on ASC")
ver_id = versions[0]["id"]
ver_state = versions[0]["attributes"]["appStoreState"]
print(f"  {ver_id}  state={ver_state}")

# find en-US localization
resp = api("GET", f"/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations")
loc = next((l for l in resp.get("data",[]) if l["attributes"]["locale"]=="en-US"), None)
if not loc: sys.exit("ERROR: no en-US localization")
loc_id = loc["id"]
print(f"  localization: {loc_id}")

# delete existing screenshot sets
resp = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
for s in resp.get("data", []):
    print(f"  deleting {s['attributes']['screenshotDisplayType']} set {s['id']}")
    api("DELETE", f"/v1/appScreenshotSets/{s['id']}")

def upload_shots(shots_dir, display_type):
    resp = api("POST", "/v1/appScreenshotSets", {"data":{"type":"appScreenshotSets","attributes":{"screenshotDisplayType":display_type},"relationships":{"appStoreVersionLocalization":{"data":{"type":"appStoreVersionLocalizations","id":loc_id}}}}})
    set_id = resp["data"]["id"]
    print(f"  created {display_type} set {set_id}")
    shots = sorted(f for f in os.listdir(shots_dir) if f.endswith(".png") and len(f)>=3 and f[:2].isdigit() and f[2]=="-")
    for fn in shots:
        fb = open(os.path.join(shots_dir, fn),"rb").read()
        size = len(fb); md5 = hashlib.md5(fb).hexdigest()
        res = api("POST","/v1/appScreenshots",{"data":{"type":"appScreenshots","attributes":{"fileName":fn,"fileSize":size},"relationships":{"appScreenshotSet":{"data":{"type":"appScreenshotSets","id":set_id}}}}})
        shot_id = res["data"]["id"]
        for op in res["data"]["attributes"].get("uploadOperations") or []:
            chunk = fb[op.get("offset",0):op.get("offset",0)+op.get("length",size)]
            req = urllib.request.Request(op["url"],data=chunk,method=op.get("method","PUT"),headers={h["name"]:h["value"] for h in op.get("requestHeaders",[])})
            urllib.request.urlopen(req).read()
        api("PATCH",f"/v1/appScreenshots/{shot_id}",{"data":{"type":"appScreenshots","id":shot_id,"attributes":{"uploaded":True,"sourceFileChecksum":md5}}})
        print(f"    {fn}  {len(fb)//1024} KB")

print("uploading iPhone screenshots …")
upload_shots(IPHONE_DIR, "APP_IPHONE_67")
print("uploading iPad screenshots …")
upload_shots(IPAD_DIR, "APP_IPAD_PRO_3GEN_129")

if not DO_SUBMIT:
    print("\nScreenshots uploaded. Run with --submit to submit for App Store review.")
    sys.exit(0)

# wait for screenshots to be COMPLETE
print("waiting for screenshot processing …")
for _ in range(20):
    time.sleep(8)
    sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?include=appScreenshots")
    included = sets.get("included") or []
    states = [x["attributes"].get("assetDeliveryState",{}).get("state","?") for x in included if x["type"]=="appScreenshots"]
    pending = [s for s in states if s not in ("COMPLETE","UPLOAD_COMPLETE")]
    if not pending: break
    print(f"  pending: {len(pending)} …")

# find build for this version
print("finding build …")
resp = api("GET", f"/v1/builds?filter[app]={ADAM_ID}&filter[version]={sys.argv[1].split('.')[-1]}&sort=-uploadedDate&limit=10")
# filter by any valid build
all_builds = api("GET", f"/v1/builds?filter[app]={ADAM_ID}&sort=-uploadedDate&limit=20")
build_id = None
for b in all_builds.get("data",[]):
    if not b["attributes"].get("expired") and b["attributes"].get("processingState")=="VALID":
        build_id = b["id"]
        bv = b["attributes"]["version"]
        print(f"  using build {build_id} v{bv}")
        break
if not build_id: sys.exit("ERROR: no valid build found")

# attach build
api("PATCH", f"/v1/appStoreVersions/{ver_id}", {"data":{"type":"appStoreVersions","id":ver_id,"relationships":{"build":{"data":{"type":"builds","id":build_id}}}}})
print("  build attached")

# patch whatsNew if empty
loc_detail = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}?fields[appStoreVersionLocalizations]=whatsNew")
if not loc_detail["data"]["attributes"].get("whatsNew"):
    print("  patching whatsNew (empty) — add release notes to Changelog.swift and re-run")
    api("PATCH", f"/v1/appStoreVersionLocalizations/{loc_id}", {"data":{"type":"appStoreVersionLocalizations","id":loc_id,"attributes":{"whatsNew":f"Version {VERSION} — see What's New in the app for full release notes."}}})

# create and submit review submission
print("creating review submission …")
sub = api("POST","/v1/reviewSubmissions",{"data":{"type":"reviewSubmissions","attributes":{"platform":"IOS"},"relationships":{"app":{"data":{"type":"apps","id":ADAM_ID}}}}})
sub_id = sub["data"]["id"]
api("POST","/v1/reviewSubmissionItems",{"data":{"type":"reviewSubmissionItems","relationships":{"reviewSubmission":{"data":{"type":"reviewSubmissions","id":sub_id}},"appStoreVersion":{"data":{"type":"appStoreVersions","id":ver_id}}}}})
print(f"  submission {sub_id} — submitting to Apple …")
api("PATCH",f"/v1/reviewSubmissions/{sub_id}",{"data":{"type":"reviewSubmissions","id":sub_id,"attributes":{"submitted":True}}})
print(f"\n{VERSION} is now WAITING_FOR_REVIEW at Apple.")
PYEOF

rm -rf "$TMP_DIR"
echo "==> done"
