# modules/system/security.nix
# Firejail sandboxing, GnuPG, AppArmor, PAM, GNOME Keyring

{ pkgs, ... }:

let
  # ── Brave (main profile) ──────────────────────────────────────────────────
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

  brave-hw-profile = pkgs.writeText "brave-hw.profile" ''
    include ${pkgs.firejail}/etc/firejail/brave.profile
    whitelist ''${HOME}/.config/brave-hw
    whitelist ''${HOME}/Downloads
    whitelist ''${HOME}/Documents
    whitelist ''${HOME}/Pictures
    whitelist ''${HOME}/Videos
    ignore private-dev
    ignore nou2f
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

  brave-hw-wrapper = pkgs.writeShellScriptBin "brave-hw" ''
    FIREJAIL=/run/wrappers/bin/firejail
    BRAVE=${brave-wayland}/bin/brave
    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run --user --quiet --scope --slice=app-brave.slice"
    USER_DATA_DIR="$HOME/.config/brave-hw"
    mkdir -p "$USER_DATA_DIR"

    if "$FIREJAIL" --list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q ":brave-hw:"; then
      exec $SYSTEMD_RUN "$FIREJAIL" --join=brave-hw "$BRAVE" --user-data-dir="$USER_DATA_DIR" "$@"
    else
      exec $SYSTEMD_RUN "$FIREJAIL" --name=brave-hw --profile=${brave-hw-profile} "$BRAVE" --user-data-dir="$USER_DATA_DIR" "$@"
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
      # mpv — uses the upstream built-in profile which already handles
      # yt-dlp, Lua scripts, ~/Videos, ~/Music, ~/Pictures, ~/Downloads
      mpv = {
        executable = "${pkgs.mpv}/bin/mpv";
        profile = "${pkgs.firejail}/etc/firejail/mpv.profile";
      };
    };
  };

  # Brave and Claude use custom shell wrappers (not wrappedBinaries) because
  # they need sandbox join logic and systemd scope management that the simple
  # wrappedBinaries pattern can't express.

  # ── AppArmor ──────────────────────────────────────────────────────────────
  security.apparmor.enable = true;

  # ── Polkit ────────────────────────────────────────────────────────────────
  security.polkit.enable = true;
  security.polkit.adminIdentities = [ "unix-user:nimbus" ];

  # ── Sudo ──────────────────────────────────────────────────────────────────
  security.sudo.wheelNeedsPassword = true;

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
  services.gnome.gnome-keyring.enable = true;

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = [
    brave-wrapper
    brave-hw-wrapper
    claude-wrapper
    pkgs.libsecret
  ];
}
