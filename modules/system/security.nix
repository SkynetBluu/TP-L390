# modules/system/security.nix
# Firejail sandboxing, AppArmor, PAM, GNOME Keyring

{ pkgs, ... }:

let
  # ── Brave ─────────────────────────────────────────────────────────────────
  # Wayland-optimised build with Firejail sandbox join logic and systemd
  # scope management — wrappedBinaries can't express these requirements
  brave-wayland = pkgs.brave.override {
    commandLineArgs = [
      # --ozone-platform-hint=wayland is the modern way; it auto-falls-back to
      # X11 if Wayland isn't available. UseOzonePlatform / --ozone-platform=...
      # are implied by the hint, so they're not needed.
      "--ozone-platform-hint=wayland"
      "--enable-features=TouchpadOverscrollHistoryNavigation,WaylandWindowDecorations"
      # AsyncDns + DoH disabled so name resolution flows through systemd-resolved
      # (DNSSEC + fallback DNS configured in modules/system/networking.nix).
      # Without this, Brave does its own DNS and bypasses the resolved stack.
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

  # ── Claude Code ───────────────────────────────────────────────────────────
  claude-wrapper = pkgs.writeShellScriptBin "claude" ''
    FIREJAIL=/run/wrappers/bin/firejail
    CLAUDE=${pkgs.claude-code}/bin/claude
    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run --user --quiet --scope --slice=app-claude.slice"

    exec $SYSTEMD_RUN "$FIREJAIL" \
      --noprofile \
      --whitelist="$HOME/projects" \
      --whitelist="$HOME/Documents" \
      --whitelist="$HOME/.config/claude" \
      --whitelist="$HOME/.local/share/claude" \
      --whitelist="$HOME/.config/nixos" \
      --whitelist="$HOME/.claude" \
      --whitelist="$HOME/.anthropic" \
      --whitelist=/run/current-system \
      --whitelist=/nix/store \
      --private-etc=ssl,static,hosts,nsswitch.conf \
      --dns=1.1.1.1 \
      --dns=1.0.0.1 \
      --env=HOME="$HOME" \
      --env=DISABLE_AUTOUPDATER=1 \
      --env=DISABLE_UPDATES=1 \
      --caps.drop=all \
      --nonewprivs \
      --noroot \
      --nosound \
      --novideo \
      --private-tmp \
      --protocol=unix,inet,inet6 \
      "$CLAUDE" "$@"

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

  # Brave and Claude use shell wrappers (not wrappedBinaries) because they
  # need sandbox join logic and systemd scope management

  # ── AppArmor ──────────────────────────────────────────────────────────────
  security.apparmor.enable = true;

  # ── Polkit ────────────────────────────────────────────────────────────────
  # Default adminIdentities = [ "unix-group:wheel" ] is already correct since
  # nimbus is in wheel. Don't override it — doing so locks polkit admin to
  # a specific username and breaks if a second wheel user is ever added.
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

  # ── GNOME Keyring ─────────────────────────────────────────────────────────
  # Secret Service provider for Electron credential storage
  services.gnome.gnome-keyring.enable = true;

  # ── Packages ──────────────────────────────────────────────────────────────
  # qbittorrent / mpv / yt-dlp are installed via programs.firejail.wrappedBinaries
  # above — don't list the raw packages here or you'll collide on /run/current-system/sw/bin.
  environment.systemPackages = [
    brave-wrapper
    claude-wrapper
    pkgs.libsecret
  ];
}
