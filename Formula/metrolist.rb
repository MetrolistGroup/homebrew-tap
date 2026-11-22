class Metrolist < Formula
  desc "YouTube Music client"
  homepage "https://github.com/MetrolistGroup/Metrolist"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/MetrolistGroup/Metrolist/releases/download/v14.0.1/metrolist-desktop-macos-arm64-14.0.1.dmg",
          using: :nounzip
      sha256 "1ffc14e691ce5bcb50d4a08d3aba6fba725458e4a07edb9125cbc08c7001ae29"
    else
      url "https://github.com/MetrolistGroup/Metrolist/releases/download/v14.0.1/metrolist-desktop-macos-x64-14.0.1.dmg",
          using: :nounzip
      sha256 "43fbb98130f23532c7217db4152f67eee257a543fc1926a5f27a70c9b49bbfba"
    end
  elsif Hardware::CPU.arm?
    url "https://github.com/MetrolistGroup/Metrolist/releases/download/v14.0.1/metrolist-desktop-linux-arm64-14.0.1.AppImage"
    sha256 "521100e8ea7810a92fecb16a3b0ca6bb4c23beb93075ac365aee1159ce19d0ca"
  else
    url "https://github.com/MetrolistGroup/Metrolist/releases/download/v14.0.1/metrolist-desktop-linux-x64-14.0.1.AppImage"
    sha256 "b3c363a95e391be4e26a52bf95ae07a69f59639cdc63edb1f34183c5ebca4230"
  end
  license "GPL-3.0-only"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    depends_on "sevenzip" => :build
  end

  def install
    if OS.mac?
      # The build sandbox cannot mount a DMG. -snld keeps the runtime's symlinks.
      system "7zz", "x", "-snld", "-y", "-oextracted", Dir["*.dmg"].first
      libexec.install "extracted/Metrolist/Metrolist.app"
      # The jpackage launcher finds its runtime relative to its own path.
      (bin/"metrolist").write <<~SH
        #!/bin/sh
        exec "#{libexec}/Metrolist.app/Contents/MacOS/Metrolist" "$@"
      SH
    else
      appimage = Dir["*.AppImage"].first
      chmod 0755, appimage
      # The AppImage runtime unpacks itself without FUSE.
      system "./#{appimage}", "--appimage-extract"
      libexec.install Dir["squashfs-root/*"]
      (bin/"metrolist").write <<~SH
        #!/bin/sh
        # AppRun expects the AppImage runtime to set APPDIR.
        APPDIR="#{libexec}" exec "#{libexec}/AppRun" "$@"
      SH
      (share/"applications/metrolist.desktop").write <<~DESKTOP
        [Desktop Entry]
        Type=Application
        Name=Metrolist
        Comment=YouTube Music client
        Exec=#{opt_bin}/metrolist %u
        Icon=#{opt_libexec}/Metrolist.png
        StartupWMClass=Metrolist
        Categories=AudioVideo;Audio;Player;
        MimeType=x-scheme-handler/metrolist;x-scheme-handler/metrolist-auth;
        Terminal=false
      DESKTOP
    end
  end

  def caveats
    if OS.mac?
      <<~EOS
        Metrolist is not signed or notarized. If macOS blocks the first launch, verify the
        download, then use Open Anyway in System Settings > Privacy & Security:
          https://support.apple.com/en-us/102445
      EOS
    else
      <<~EOS
        To show Metrolist in your application menu, link its desktop entry:
          ln -sf #{opt_share}/applications/metrolist.desktop ~/.local/share/applications/
      EOS
    end
  end

  test do
    if OS.mac?
      assert_predicate libexec/"Metrolist.app/Contents/MacOS/Metrolist", :executable?
    else
      assert_predicate libexec/"AppRun", :executable?
      assert_path_exists libexec/"bin/Metrolist"
    end
  end
end
