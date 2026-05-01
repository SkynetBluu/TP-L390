# modules/system/security.nix
# Firejail sandboxing, AppArmor, PAM, GNOME Keyring

{ pkgs, ... }:

let
  # ── Brave ─────────────────────────────────────────────────────────────────
  # Wayland-optimised build with Firejail sandbox join logic and systemd
  # scope management — wrappedBinaries can't express these requirements
  brave-wayland = pkgs.brave.override {
    commandLineArgs = [
      "--ozone-platform=wayland"
      "--ozone-platform-hint=wayland"
      "--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,WaylandWindowDecorations"
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
      --whitelist="$HOME/.anthropic" \
      --whitelist=/run/current-system \
      --whitelist=/nix/store \
      --env=HOME="$HOME" \
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
        profile    = "${pkgs.firejail}/etc/firejail/mpv.profile";
      };
    };
  };

  # Brave and Claude use shell wrappers (not wrappedBinaries) because they
  # need sandbox join logic and systemd scope management

  # ── AppArmor ──────────────────────────────────────────────────────────────
  security.apparmor.enable = true;

  # ── Polkit ────────────────────────────────────────────────────────────────
  security.polkit.enable = true;
  security.polkit.adminIdentities = [ "unix-user:nimbus" ];

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
    login.enableGnomeKeyring  = true;
    passwd.enableGnomeKeyring = true;
    hyprlock                  = {};
  };

  # ── GNOME Keyring ─────────────────────────────────────────────────────────
  # Secret Service provider for Electron credential storage
  services.gnome.gnome-keyring.enable = true;

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = [
    brave-wrapper
    claude-wrapper
    pkgs.libsecret
  ];
}
