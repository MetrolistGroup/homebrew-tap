cask "metrolist" do
  arch arm: "arm64", intel: "x64"
  os macos: "macos", linux: "linux"
  url_end = on_system_conditional macos: "dmg", linux: "AppImage"

  version "14.0.1"
  sha256 arm:          "1ffc14e691ce5bcb50d4a08d3aba6fba725458e4a07edb9125cbc08c7001ae29",
         intel:        "43fbb98130f23532c7217db4152f67eee257a543fc1926a5f27a70c9b49bbfba",
         arm64_linux:  "521100e8ea7810a92fecb16a3b0ca6bb4c23beb93075ac365aee1159ce19d0ca",
         x86_64_linux: "b3c363a95e391be4e26a52bf95ae07a69f59639cdc63edb1f34183c5ebca4230"

  on_macos do
    app "Metrolist.app"

    caveats <<~EOS
      Metrolist is not signed or notarized. If macOS blocks the first launch, verify the
      download, then use Open Anyway in System Settings > Privacy & Security:
        https://support.apple.com/en-us/102445
    EOS
  end
  on_linux do
    app_image "metrolist-desktop-linux-#{arch}-#{version}.AppImage", target: "Metrolist.AppImage"
  end

  url "https://github.com/MetrolistGroup/Metrolist/releases/download/v#{version}/metrolist-desktop-#{os}-#{arch}-#{version}.#{url_end}"
  name "Metrolist"
  desc "YouTube Music client"
  homepage "https://github.com/MetrolistGroup/Metrolist"

  livecheck do
    url :url
    strategy :github_latest
  end

  zap trash: [
    "~/.cache/metrolist",
    "~/.config/metrolist",
    "~/.local/share/metrolist",
    "~/.local/state/metrolist",
    "~/Library/Saved Application State/com.metrolist.desktop.savedState",
  ]
end
