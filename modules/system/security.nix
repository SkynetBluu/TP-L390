# modules/system/security.nix
# Firejail sandboxing, GnuPG, AppArmor, PAM, GNOME Keyring

{ pkgs, ... }:

let
  # Brave with Wayland flags
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

  # Custom wrapper: conditionally joins existing sandbox or creates new one
  # (avoids --profile conflicts when Brave is already running)
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

  # Claude Code wrapper — sandboxed with Firejail
  # Only whitelists ~/projects, ~/.config/claude and ~/.local/share/claude
  # Adjust ~/projects to wherever you keep your code
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
in
{
  # ── Firejail ──────────────────────────────────────────────────────────────
  programs.firejail = {
    enable = true;
    # NOTE: brave uses the custom wrapper above, not wrappedBinaries
  };

  # ── AppArmor ──────────────────────────────────────────────────────────────
  security.apparmor.enable = true;

  # ── Polkit ────────────────────────────────────────────────────────────────
  security.polkit.enable = true;

  security.polkit.adminIdentities = [ "unix-user:nimbus" ];

  # ── Sudo ──────────────────────────────────────────────────────────────────
  security.sudo.wheelNeedsPassword = true;

  # Passwordless TLP battery threshold management only
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
  # Secret Service provider for VS Code / Electron credential storage
  services.gnome.gnome-keyring.enable = true;

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = [
    brave-wrapper
    brave-hw-wrapper
    claude-wrapper
    pkgs.libsecret # secret-tool for debugging GNOME Keyring
  ];
}
