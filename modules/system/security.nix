# modules/system/security.nix
# Firejail sandboxing, AppArmor, PAM, GNOME Keyring

{ pkgs, ... }:

let
  # ── Brave ─────────────────────────────────────────────────────────────────
  # Wayland-optimised build with Firejail sandbox join logic and systemd
  # scope management — wrappedBinaries can't express these requirements
  brave-wayland = pkgs.brave.override {
    commandLineArgs = [
      # Hint auto-falls-back to X11; implies UseOzonePlatform.
      "--ozone-platform-hint=wayland"
      "--enable-features=TouchpadOverscrollHistoryNavigation,WaylandWindowDecorations"
      # AsyncDns + DoH off so DNS flows through systemd-resolved (DNSSEC chain
      # in modules/system/networking.nix).
      "--disable-features=WaylandWpColorManagerV1,AsyncDns"
      "--dns-over-https-mode=off"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--enable-smooth-scrolling"
    ];
  };

  brave-profile = pkgs.writeText "brave-strict.profile" ''
    include ${pkgs.firejail}/etc/firejail/brave.profile
    whitelist ''${HOME}/Downloads
  '';

  brave-wrapper = pkgs.writeShellScriptBin "brave" ''
    FIREJAIL=/run/wrappers/bin/firejail
    BRAVE=${brave-wayland}/bin/brave
    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run --user --quiet --scope --slice=app-brave.slice"

    if "$FIREJAIL" --list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q ":brave:"; then
      exec $SYSTEMD_RUN "$FIREJAIL" --join=brave "$BRAVE" "$@"
    else
      exec $SYSTEMD_RUN "$FIREJAIL" --name=brave --profile=${brave-profile} "$BRAVE" "$@"
    fi
  '';

in
{
  # ── Firejail ──────────────────────────────────────────────────────────────
  programs.firejail = {
    enable = true;

    wrappedBinaries = {
      # mpv — upstream profile covers ~/Videos, ~/Music, ~/Pictures,
      # ~/Downloads, yt-dlp, Lua scripts, VA-API, PipeWire
      mpv = {
        executable = "${pkgs.mpv}/bin/mpv";
        profile = "${pkgs.firejail}/etc/firejail/mpv.profile";
      };
      # yt-dlp — upstream profile whitelists ~/Music, ~/Videos, ~/Downloads,
      # ~/.config/yt-dlp, ~/.cache/yt-dlp; the scripts in modules/home/mpv.nix
      # call bare `yt-dlp` so PATH resolves to this firejail wrapper.
      yt-dlp = {
        executable = "${pkgs.yt-dlp}/bin/yt-dlp";
        profile = "${pkgs.firejail}/etc/firejail/yt-dlp.profile";
      };
      qbittorrent = {
        executable = "${pkgs.qbittorrent}/bin/qbittorrent";
        profile = "${pkgs.firejail}/etc/firejail/qbittorrent.profile";
      };
    };
  };

  # Brave uses a shell wrapper (not wrappedBinaries) because it
  # needs sandbox join logic and systemd scope management.
  # Claude is no longer here — it runs as its own user; see modules/system/claude.nix.

  # ── AppArmor ──────────────────────────────────────────────────────────────
  security.apparmor.enable = true;

  # ── Polkit ────────────────────────────────────────────────────────────────
  # Don't set adminIdentities — default `unix-group:wheel` already covers nimbus.
  security.polkit.enable = true;

  # ── Sudo ──────────────────────────────────────────────────────────────────
  security.sudo.wheelNeedsPassword = true;

  # Passwordless sudo only for TLP battery threshold management
  security.sudo.extraRules = [
    {
      users = [ "nimbus" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/tlp setcharge *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # ── PAM ───────────────────────────────────────────────────────────────────
  security.pam.services = {
    login.enableGnomeKeyring = true;
    passwd.enableGnomeKeyring = true;
    hyprlock = { };
  };

  # ── Resource limits ───────────────────────────────────────────────────────
  # 1024 FDs default is too low for modern Wayland sessions; pipewire +
  # waybar + hyprland plugins + portals can exhaust it during activation.
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
  ];

  # ── GNOME Keyring ─────────────────────────────────────────────────────────
  # Secret Service provider for Electron credential storage
  services.gnome.gnome-keyring.enable = true;

  # ── Packages ──────────────────────────────────────────────────────────────
  # qbittorrent / mpv / yt-dlp are installed via programs.firejail.wrappedBinaries
  # above — don't list the raw packages here or you'll collide on /run/current-system/sw/bin.
  environment.systemPackages = [
    brave-wrapper
    pkgs.libsecret
  ];
}
