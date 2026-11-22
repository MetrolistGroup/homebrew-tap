# Metrolist Homebrew tap

Installs the [Metrolist](https://github.com/MetrolistGroup/Metrolist) desktop app from its GitHub releases.

Homebrew only installs from taps you trust, so trust this one once:

```sh
brew trust metrolistgroup/tap
```

macOS and Linux (x86_64 and ARM64) can use the cask or the formula:

```sh
brew install --cask metrolistgroup/tap/metrolist
brew install metrolistgroup/tap/metrolist
```

The cask installs Metrolist.app on macOS. On Linux it installs the AppImage and an application menu entry. If `~/.local/share/applications/Metrolist.desktop` already exists, run `brew install --cask --force metrolistgroup/tap/metrolist` so Homebrew can replace it. The formula adds a `metrolist` command. On Linux it unpacks the release AppImage, so FUSE is not needed, and `brew info metrolistgroup/tap/metrolist` prints the command that links its desktop entry. On macOS the command launches the installed app.

Metrolist is not signed or notarized on macOS. If the first launch is blocked, verify the download and use Open Anyway in System Settings > Privacy & Security ([Apple's instructions](https://support.apple.com/en-us/102445)). Do not turn off Gatekeeper.

`brew uninstall --zap --cask metrolist` also removes Metrolist's settings, library database and downloads. Export a backup first if you want to keep them.

The tap updates itself: a scheduled workflow points the cask and formula at the latest stable release and its published `SHA256SUMS`, then runs the install tests on macOS and Linux. Nightly builds are not packaged here.
