class Metrolist < Formula
  desc "YouTube Music client"
  homepage "https://github.com/MetrolistGroup/Metrolist"
  if Hardware::CPU.arm?
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

  depends_on :linux

  def install
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

  def caveats
    <<~EOS
      To show Metrolist in your application menu, link its desktop entry:
        ln -sf #{opt_share}/applications/metrolist.desktop ~/.local/share/applications/
    EOS
  end

  test do
    assert_predicate libexec/"AppRun", :executable?
    assert_path_exists libexec/"bin/Metrolist"
  end
end
