# Update the url and sha256 after each release.

class Windowmap < Formula
  desc "Global hotkey window picker for macOS"
  homepage "https://github.com/WindowMap/WindowMap"
  version "0.1.0"
  url "https://github.com/WindowMap/WindowMap/releases/download/v#{version}/windowmap.tar.gz"
  sha256 "2897e3e9d98b844186f4a3cc1346189e511834c471a5b620080d4941549717e4"

  depends_on macos: :sonoma

  def install
    libexec.install "windowmap"
    (bin/"windowmap").write <<~EOS
      #!/bin/sh
      export WINDOWMAP_HOME="${WINDOWMAP_HOME:-$HOME/.config/windowmap}"
      exec "#{libexec}/windowmap" "$@"
    EOS
    (bin/"windowmap").chmod(0755)
    pkgshare.install buildpath/"Resources/config.toml.example"
  end

  def post_install
    config_dir = Pathname.new("#{Dir.home}/.config/windowmap")
    config_file = config_dir/"config.toml"
    unless config_file.exist?
      config_dir.mkpath
      config_file.write (pkgshare/"config.toml.example").read
    end
  end

  service do
    run [opt_bin/"windowmap"]
    keep_alive crashed: true
    log_path var/"log/windowmap.log"
    error_log_path var/"log/windowmap.log"
  end

  def caveats
    <<~EOS
      A default config has been created at ~/.config/windowmap/config.toml
      Edit it to configure your hotkey and preferences, then start the service:
        brew services start windowmap

      Logs are written to #{var}/log/windowmap.log

      Grant Accessibility and Screen Recording permissions when prompted, or add manually:
        System Settings → Privacy & Security → Accessibility → windowmap
        System Settings → Privacy & Security → Screen Recording → windowmap
    EOS
  end
end
