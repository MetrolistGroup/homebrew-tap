cask "metrolist" do
  arch arm: "arm64", intel: "x64"

  version "14.0.0"
  sha256 arm:   "cbee8dce25f62ed1ba0ca89538b7a43e128995f188108722293ac9f752291e48",
         intel: "3ab2634cc5a5bdd29e2a000ee08ada9b6bc8886e883bc0c97b9ab5060a098cc1"

  url "https://github.com/MetrolistGroup/Metrolist/releases/download/v#{version}/metrolist-desktop-macos-#{arch}-#{version}.dmg"
  name "Metrolist"
  desc "YouTube Music client"
  homepage "https://github.com/MetrolistGroup/Metrolist"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "Metrolist.app"

  zap trash: [
    "~/.cache/metrolist",
    "~/.config/metrolist",
    "~/.local/share/metrolist",
    "~/.local/state/metrolist",
    "~/Library/Saved Application State/com.metrolist.desktop.savedState",
  ]

  caveats <<~EOS
    Metrolist is not signed or notarized. If macOS blocks the first launch, verify the
    download, then use Open Anyway in System Settings > Privacy & Security:
      https://support.apple.com/en-us/102445
  EOS
end
