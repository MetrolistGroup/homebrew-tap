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
SHA = r"[0-9a-f]{64}"


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
        if re.fullmatch(SHA, digest):
            sums[name] = digest
    return version, sums


def need(sums, name):
    if name not in sums:
        raise SystemExit(f"SHA256SUMS lists no {name}")
    return sums[name]


def update_cask(text, version, sums):
    arm = need(sums, f"metrolist-desktop-macos-arm64-{version}.dmg")
    intel = need(sums, f"metrolist-desktop-macos-x64-{version}.dmg")
    arm64_linux = need(sums, f"metrolist-desktop-linux-arm64-{version}.AppImage")
    x64_linux = need(sums, f"metrolist-desktop-linux-x64-{version}.AppImage")
    text, count = re.subn(r'(?m)^  version "[^"]+"', f'  version "{version}"', text)
    if count != 1:
        raise SystemExit(f"Cask version stanza matched {count} times")
    sha = (
        f'  sha256 arm:          "{arm}",\n'
        f'         intel:        "{intel}",\n'
        f'         arm64_linux:  "{arm64_linux}",\n'
        f'         x86_64_linux: "{x64_linux}"'
    )
    text, count = re.subn(
        rf'  sha256 arm:\s+"{SHA}",\s+intel:\s+"{SHA}",\s+'
        rf'arm64_linux:\s+"{SHA}",\s+x86_64_linux:\s+"{SHA}"',
        sha,
        text,
    )
    if count != 1:
        raise SystemExit(f"Cask sha256 stanza matched {count} times")
    return text


def update_formula(text, version, sums):
    specs = (
        ("macos", "arm64", "dmg"),
        ("macos", "x64", "dmg"),
        ("linux", "arm64", "AppImage"),
        ("linux", "x64", "AppImage"),
    )
    for os_name, arch, ext in specs:
        name = f"metrolist-desktop-{os_name}-{arch}-{version}.{ext}"
        url = f"https://github.com/{REPO}/releases/download/v{version}/{name}"
        nounzip = ',\n          using: :nounzip' if ext == "dmg" else ""
        pattern = (
            rf'url "https://github\.com/{REPO}/releases/download/v[^/]+/'
            rf'metrolist-desktop-{os_name}-{arch}-[^"]+\.{ext}"'
            rf'(?:,\n\s+using: :nounzip)?\n'
            rf'(\s+)sha256 "{SHA}"'
        )
        text, count = re.subn(
            pattern,
            lambda m, url=url, name=name, nounzip=nounzip: f'url "{url}"{nounzip}\n{m.group(1)}sha256 "{need(sums, name)}"',
            text,
        )
        if count != 1:
            raise SystemExit(f"Formula {os_name} {arch} url/sha256 matched {count} times")
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
