"""Point the cask and formula at the latest stable Metrolist release.

Reads the release's SHA256SUMS, so no checksum is computed from downloads here.
Exits 0 without changes when the files already match.
"""

import json
import os
import re
import sys
import urllib.request
from pathlib import Path

REPO = "MetrolistGroup/Metrolist"
ROOT = Path(__file__).resolve().parent.parent
CASK = ROOT / "Casks/metrolist.rb"
FORMULA = ROOT / "Formula/metrolist.rb"


def fetch(url):
    request = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json", "User-Agent": "metrolist-homebrew-tap"})
    token = os.environ.get("GITHUB_TOKEN")
    if token and url.startswith("https://api.github.com/"):
        request.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def latest_release():
    release = json.loads(fetch(f"https://api.github.com/repos/{REPO}/releases/latest"))
    tag = release["tag_name"]
    version = tag.removeprefix("v")
    if not re.fullmatch(r"\d+(\.\d+)*", version):
        raise SystemExit(f"Unexpected release tag {tag!r}")
    sums_asset = next((a for a in release["assets"] if a["name"] == "SHA256SUMS"), None)
    if sums_asset is None:
        raise SystemExit(f"{tag} has no SHA256SUMS asset")
    sums = {}
    for line in fetch(sums_asset["browser_download_url"]).decode().splitlines():
        digest, _, name = line.strip().partition("  ")
        if re.fullmatch(r"[0-9a-f]{64}", digest):
            sums[name] = digest
    return version, sums


def need(sums, name):
    if name not in sums:
        raise SystemExit(f"SHA256SUMS lists no {name}")
    return sums[name]


def update_cask(text, version, sums):
    arm = need(sums, f"metrolist-desktop-macos-arm64-{version}.dmg")
    intel = need(sums, f"metrolist-desktop-macos-x64-{version}.dmg")
    text = re.sub(r'(?m)^  version "[^"]+"', f'  version "{version}"', text)
    text = re.sub(r'sha256 arm:\s+"[0-9a-f]{64}",\s+intel: "[0-9a-f]{64}"',
                  f'sha256 arm:   "{arm}",\n         intel: "{intel}"', text)
    return text


def update_formula(text, version, sums):
    for arch in ("x64", "arm64"):
        name = f"metrolist-desktop-linux-{arch}-{version}.AppImage"
        url = f"https://github.com/{REPO}/releases/download/v{version}/{name}"
        pattern = rf'url "https://github\.com/{REPO}/releases/download/v[^/]+/metrolist-desktop-linux-{arch}-[^"]+\.AppImage"\n(\s+)sha256 "[0-9a-f]{{64}}"'
        text, count = re.subn(pattern, lambda m: f'url "{url}"\n{m.group(1)}sha256 "{need(sums, name)}"', text)
        if count != 1:
            raise SystemExit(f"Formula has no single {arch} url/sha256 pair")
    return text


def main():
    version, sums = latest_release()
    changed = False
    for path, update in ((CASK, update_cask), (FORMULA, update_formula)):
        before = path.read_text()
        after = update(before, version, sums)
        if after != before:
            path.write_text(after)
            changed = True
    print(f"version={version}")
    print(f"changed={'true' if changed else 'false'}")
    if out := os.environ.get("GITHUB_OUTPUT"):
        with open(out, "a") as stream:
            stream.write(f"version={version}\nchanged={'true' if changed else 'false'}\n")


if __name__ == "__main__":
    sys.exit(main())
