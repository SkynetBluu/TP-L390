# modules/system/hyprland.nix
# Hyprland Wayland compositor — system-level config

{ pkgs, inputs, ... }:

let
  # Pin Mesa to Hyprland's flake input to prevent FPS drops from version mismatch
  hyprlandPkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  # ── Mesa (pinned to Hyprland flake) ──────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    package = hyprlandPkgs.mesa;
    package32 = hyprlandPkgs.pkgsi686Linux.mesa;
  };

  # ── Hyprland ──────────────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    withUWSM = true; # Universal Wayland Session Manager — recommended
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # ── Display Manager ───────────────────────────────────────────────────────
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze";
  };

  # ── XDG Portals ───────────────────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    wlr.enable = false; # Use Hyprland's own portal
    xdgOpenUsePortal = false; # Hyprland portal doesn't fully support OpenURI
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
  };

  # ── Wayland environment variables ─────────────────────────────────────────
  # NOTE: XDG_CURRENT_DESKTOP, XDG_SESSION_TYPE set automatically by UWSM
  environment.sessionVariables = {
    WALLPAPER = $WALLPAPER;
    NIXOS_OZONE_WL = "1"; # Electron apps (VS Code, Brave)
    MOZ_ENABLE_WAYLAND = "1"; # Firefox
    QT_QPA_PLATFORM = "wayland;xcb"; # Qt apps (xcb fallback)
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    CLUTTER_BACKEND = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # Intel VA-API hardware video decode
    LIBVA_DRIVER_NAME = "iHD";
  };

  # ── Security ──────────────────────────────────────────────────────────────
  security.polkit.enable = true;

  # ── Suspend / resume fix ──────────────────────────────────────────────────
  # Freeze Hyprland before suspend to prevent GPU access during s2idle
  # Prevents SEGV crashes on resume from stale DRM/GPU state
  systemd.services.hyprland-suspend = {
    description = "Freeze Hyprland before suspend";
    before = [ "systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service" ];
    wantedBy = [ "systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.procps}/bin/pkill -STOP -f '/bin/Hyprland'";
    };
  };

  systemd.services.hyprland-resume = {
    description = "Unfreeze Hyprland after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      # 4s delay gives Intel GPU/DRM time to reinitialise after s2idle
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 4 && ${pkgs.procps}/bin/pkill -CONT -f /bin/Hyprland'";
    };
  };

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    wayland
    wayland-protocols
    wayland-utils
    wl-clipboard
    wl-clipboard-x11
    grim
    slurp
    wf-recorder
    libnotify
    xwayland
  ];
}
