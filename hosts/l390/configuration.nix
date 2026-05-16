# hosts/l390/configuration.nix
# Main NixOS configuration for ThinkPad L390 (Intel i5-8365U / UHD 620)

{ config, pkgs, inputs, ... }:

{

  # ── System ────────────────────────────────────────────────────────────────

  networking.hostName = "l390";
  time.timeZone = "Europe/London";

  system.stateVersion = "24.11"; # Do not change after first install

  # ── Hardware ──────────────────────────────────────────────────────────────

  hardware.cpu.intel.updateMicrocode = true;

  # Intel UHD 620 graphics
  # Mesa is pinned to Hyprland's flake input in modules/system/hyprland.nix
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      intel-vaapi-driver
    ];
  };

  hardware.enableRedistributableFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # ── Power Management ──────────────────────────────────────────────────────

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
      USB_AUTOSUSPEND = 1;
      # Boot defaults match the "balanced" mode of the battery-mode script
      # (modules/home/scripts.nix) so Super+M cycles meaningfully from the
      # current state. The user can adjust at runtime; tlp persists thresholds
      # across reboots via /var/lib/tlp.
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;

  # ── Boot / Hibernation ────────────────────────────────────────────────────
  # disko declares cryptswap (see hosts/l390/disko-config.nix) and sets
  # resumeDevice = true on the swap content, which causes disko to set
  # boot.resumeDevice to /dev/mapper/cryptswap automatically. No manual
  # declaration needed here.

  # ── Packages ──────────────────────────────────────────────────────────────

  # Packages live in three places:
  #   - environment.systemPackages here    → system-wide, available pre-login (rescue shell, recovery)
  #   - home.packages (modules/home/*.nix) → user-only, requires a logged-in session
  #   - programs.X / services.X            → home-manager modules with config attached
  #
  # Anything user-facing with a home-manager config (alacritty, mpv, etc.) lives
  # in home. Packages that should work from a TTY / recovery shell live here.
  environment.systemPackages = with pkgs; [

    # Desktop daemons / system applets (must be on system PATH so root services can call them too)
    cliphist
    awww
    brightnessctl
    # polkit agent: hyprpolkitagent (Hyprland-native, lighter than polkit-kde)
    # is enabled via services.hyprpolkitagent in modules/system/hyprland.nix

    # Core utilities — kept system-wide so they exist in single-user / recovery boots
    git
    wget
    curl
    htop
    vim
    nano

    # Hardware / system tools
    pciutils
    usbutils
    lshw
    smartmontools
    powertop
    nvme-cli

    # Btrfs
    btrfs-progs
    compsize

    # Networking
    networkmanagerapplet

    # Disk-rescue set — keep on system PATH so they work from a TTY without a user session
    parted
    gparted
    ntfs3g
    exfatprogs

    # Editors (system-wide fallback; helix + nvim home configs live in home modules)
    vscode
    neovim

    # Wayland system tools (user-facing wl-clipboard lives in home)
    xdg-utils

    # Media — system-wide because they're used by services / root contexts too
    playerctl
    pavucontrol
    inputs.nt-helper.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Bluetooth
    blueman

    # Firmware updates
    fwupd

    # Nix helper
    nh
  ];

  # ── Services ──────────────────────────────────────────────────────────────

  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;
  # upower — battery state on D-Bus. Consumed by waybar's battery module and
  # perf-mode-daemon. Works via D-Bus activation, but enable explicitly so it's
  # not load-bearing on autoload behavior.
  services.upower.enable = true;

  # dconf — needed for GTK/GNOME apps (notably nemo) to persist settings.
  # Without this every launch is a fresh slate.
  programs.dconf.enable = true;

  # MPD now runs as a user service via home-manager (see modules/home/mpd.nix).
  # It composes naturally with the user PipeWire session and avoids the
  # /run/user/<uid> race during boot.

  # ── Services ── slsk ─────────────────────────────────────────────────────

  systemd.tmpfiles.rules = [
    "d /share                  0755 root   root  - -"
    "d /share/slsk             0755 nimbus users - -"
    "d /share/slsk/share       2775 nimbus users - -"
    "d /share/slsk/downloads   2775 nimbus users - -"
    "d /share/slsk/incomplete  2775 nimbus users - -"
    "d /share/slsk/received    2775 nimbus users - -"
  ];

  # ── Data integrity (btrfs scrub + snapshots) ─────────────────────────────
  # Both intentionally OFF. Notes for when/if we turn them on:
  #
  # 1. Scrub: walks every block and verifies checksums. On this single-SSD
  #    laptop there's no redundancy so scrub can't *repair* anything — it
  #    only surfaces silent bit-rot. Monthly is the sensible cadence:
  #
  #      services.btrfs.autoScrub = {
  #        enable = true;
  #        interval = "monthly";
  #        fileSystems = [ "/" ];   # covers @, @home, @nix, @log (same fs)
  #      };
  #
  # 2. Snapper for /home only. NixOS generations already cover @ rollback;
  #    @nix is GC-managed; @home is the only subvol where snapshots add value
  #    (accidental rm, corrupted dotfiles). Snapper auto-creates and manages
  #    /home/.snapshots; the disko `@snapshots` mount at /.snapshots stays
  #    unused unless we ever decide to snapshot root too.
  #
  #      services.snapper.configs.home = {
  #        SUBVOLUME = "/home";
  #        ALLOW_USERS = [ "nimbus" ];
  #        TIMELINE_CREATE = true;
  #        TIMELINE_CLEANUP = true;
  #        TIMELINE_LIMIT_HOURLY = 5;
  #        TIMELINE_LIMIT_DAILY = 7;
  #        TIMELINE_LIMIT_WEEKLY = 4;
  #        TIMELINE_LIMIT_MONTHLY = 3;
  #        TIMELINE_LIMIT_YEARLY = 0;
  #      };
  #
  # Note: snapshots on the same disk are NOT a backup. They protect against
  # mistakes, not hardware failure. For real backup add btrbk → USB/remote.

  # ── Secrets (sops-nix) ────────────────────────────────────────────────────
  # Configure after first boot once SSH host key exists:
  #
  # sops = {
  #   defaultSopsFile = ./secrets/secrets.yaml;
  #   age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  # };

  # ── Nix settings ──────────────────────────────────────────────────────────

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
      # auto-optimise-store removed (deprecated in newer Nix). Replaced by
      # the periodic optimise timer below — same effect, runs outside builds.
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
