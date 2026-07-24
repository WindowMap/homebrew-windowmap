cask "windowmap" do
  version "1.0.0"
  sha256 "51fcb905eb6afdec93e79deec40939b3fc40e6c5160d2e1be0593c7231c1cb2f"

  url "https://github.com/WindowMap/WindowMap/releases/download/v#{version}/WindowMap.tar.gz"
  name "WindowMap"
  desc "Global hotkey window picker for macOS"
  homepage "https://github.com/WindowMap/WindowMap"

  depends_on macos: :sonoma

  app "WindowMap.app"

  postflight do
    config_dir = Pathname.new("#{Dir.home}/.config/windowmap")
    config_file = config_dir/"config.toml"
    unless config_file.exist?
      config_dir.mkpath
      config_example = "#{appdir}/WindowMap.app/Contents/Resources/config.toml.example"
      config_file.write File.read(config_example)
    end

    plist_src = "#{staged_path}/org.windowmap.plist"
    plist_dst = Pathname.new("#{Dir.home}/Library/LaunchAgents/org.windowmap.plist")

    # Generate plist from template bundled in the tar
    unless File.exist?(plist_src)
      plist_dst.dirname.mkpath
      plist_dst.write <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>org.windowmap</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{appdir}/WindowMap.app/Contents/MacOS/WindowMap</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <dict>
            <key>SuccessfulExit</key>
            <false/>
          </dict>
          <key>ProcessType</key>
          <string>Interactive</string>
          <key>StandardOutPath</key>
          <string>#{Dir.home}/Library/Logs/windowmap.log</string>
          <key>StandardErrorPath</key>
          <string>#{Dir.home}/Library/Logs/windowmap.log</string>
        </dict>
        </plist>
      XML
    end

    system "launchctl", "bootout", "gui/#{Process.uid}/org.windowmap" rescue nil
    system "launchctl", "bootstrap", "gui/#{Process.uid}", plist_dst.to_s
  end

  uninstall launchctl: "org.windowmap"

  zap trash: [
    "~/.config/windowmap",
    "~/Library/LaunchAgents/org.windowmap.plist",
    "~/Library/Logs/windowmap.log",
  ]

  caveats <<~EOS
    WindowMap is installed and will start automatically on login.

    First launch: macOS may block the app ("Apple could not verify").
    Go to System Settings → Privacy & Security → scroll down → "Open Anyway".

    Grant these permissions in System Settings → Privacy & Security:
      1. Accessibility    → WindowMap.app  (required — hotkeys)
      2. Screen Recording → WindowMap.app  (optional — window previews)

    Config: ~/.config/windowmap/config.toml (auto-reloads on save)
    Logs:   ~/Library/Logs/windowmap.log
  EOS
end
