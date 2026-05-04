#!/usr/bin/env bash
# submit-to-appstore.sh — submit the current (or specified) version for App Store review.
#
# Run this once you're happy with TestFlight testing. Does NOT touch screenshots.
#
# Usage:
#   bash scripts/submit-to-appstore.sh           # reads version from project.yml
#   bash scripts/submit-to-appstore.sh 1.12.0    # explicit version
#
# Prerequisites:
#   • ~/.cache/claude-code/peptide-tracker.env   (ASC creds, same as ship-screenshots.sh)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── resolve version ───────────────────────────────────────────────────────────
if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    VERSION="$(python3 -c "
import re
with open('$REPO/project.yml') as f: text = f.read()
m = re.search(r'MARKETING_VERSION:\s*[\"\'']?([^\"\''\n]+)', text)
print(m.group(1).strip())
")"
fi
echo "==> submitting $VERSION for App Store review"

# ── load creds ────────────────────────────────────────────────────────────────
source ~/.cache/claude-code/peptide-tracker.env

# ── python: find version → find/create reviewSubmission → submit ──────────────
python3 - "$VERSION" \
    "$ASC_API_KEY_ID" "$ASC_API_ISSUER_ID" "$ASC_API_KEY_P8" "$APP_STORE_ADAM_ID" <<'PYEOF'
import base64, json, sys, time, urllib.error, urllib.request
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils

VERSION, KEY_ID, ISSUER_ID, P8_STR, ADAM_ID = sys.argv[1:]
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
    req = urllib.request.Request(url, data=data,
          headers={"Authorization": f"Bearer {jwt()}", "Content-Type": "application/json"},
          method=method)
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        if e.code == 204: return {}
        raise RuntimeError(f"{method} {url} -> {e.code}: {e.read().decode()[:500]}")

# ── 1. find the appStoreVersion ───────────────────────────────────────────────
print(f"looking up {VERSION} …")
resp = api("GET", f"/v1/apps/{ADAM_ID}/appStoreVersions"
           f"?filter[versionString]={VERSION}&filter[platform]=IOS&limit=5")
versions = resp.get("data", [])
if not versions:
    sys.exit(f"ERROR: no version {VERSION} found on ASC — did you upload a build yet?")
ver = versions[0]
ver_id = ver["id"]
ver_state = ver["attributes"]["appStoreState"]
print(f"  {ver_id}  state={ver_state}")

if ver_state in ("READY_FOR_SALE", "PENDING_APPLE_RELEASE"):
    sys.exit(f"ERROR: {VERSION} is already live or pending release, nothing to submit.")

# ── 2. find the most recent valid build for this version ──────────────────────
print("finding build …")
all_builds = api("GET", f"/v1/builds?filter[app]={ADAM_ID}&sort=-uploadedDate&limit=25")
build_id = None
for b in all_builds.get("data", []):
    attrs = b["attributes"]
    if attrs.get("processingState") == "VALID" and not attrs.get("expired"):
        bver = attrs.get("version", "")
        build_id = b["id"]
        print(f"  using build {build_id} (build number {bver})")
        break
if not build_id:
    sys.exit("ERROR: no valid non-expired build found in ASC.")

# ── 3. attach build to the appStoreVersion (idempotent) ──────────────────────
print("attaching build …")
api("PATCH", f"/v1/appStoreVersions/{ver_id}", {"data": {"type": "appStoreVersions",
    "id": ver_id, "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}})
print("  build attached")

# ── 4. find existing READY_FOR_REVIEW submission or create one ───────────────
print("finding or creating reviewSubmission …")
existing = api("GET", f"/v1/reviewSubmissions?filter[app]={ADAM_ID}&filter[platform]=IOS&limit=10")
sub_id = None
for s in existing.get("data", []):
    if s["attributes"]["state"] == "READY_FOR_REVIEW":
        sub_id = s["id"]
        print(f"  reusing existing submission {sub_id}")
        break

if not sub_id:
    sub = api("POST", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions",
        "attributes": {"platform": "IOS"},
        "relationships": {"app": {"data": {"type": "apps", "id": ADAM_ID}}}}})
    sub_id = sub["data"]["id"]
    print(f"  created submission {sub_id}")

    # add the version to the submission
    api("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}}}})
    print("  added version item")

# ── 5. submit ─────────────────────────────────────────────────────────────────
print("submitting to Apple …")
result = api("PATCH", f"/v1/reviewSubmissions/{sub_id}", {"data": {
    "type": "reviewSubmissions", "id": sub_id,
    "attributes": {"submitted": True}}})
state = result.get("data", {}).get("attributes", {}).get("state", "unknown")
print(f"\n{VERSION} is now {state} at Apple.")
print(f"reviewSubmission: {sub_id}")
print(f"appStoreVersion:  {ver_id}")
PYEOF

echo "==> done"
