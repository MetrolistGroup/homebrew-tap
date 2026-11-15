# Metrolist Homebrew tap

Installs the [Metrolist](https://github.com/MetrolistGroup/Metrolist) desktop app from its GitHub releases.

macOS:

```sh
brew install --cask metrolistgroup/tap/metrolist
```

Linux (x86_64 and ARM64):

```sh
brew install metrolistgroup/tap/metrolist
```

On Linux the formula unpacks the release AppImage, so FUSE is not needed. Run `metrolist`, or link the desktop entry printed by `brew info metrolistgroup/tap/metrolist` to show it in your application menu.

Metrolist is not signed or notarized on macOS. If the first launch is blocked, verify the download and use Open Anyway in System Settings > Privacy & Security ([Apple's instructions](https://support.apple.com/en-us/102445)). Do not turn off Gatekeeper.

`brew uninstall --zap --cask metrolist` also removes Metrolist's settings, library database and downloads. Export a backup first if you want to keep them.

The tap updates itself: a scheduled workflow points the cask and formula at the latest stable release and its published `SHA256SUMS`, then runs the install tests. Nightly builds are not packaged here.
