# hosts/l390/configuration.nix
# Main NixOS configuration for ThinkPad L390 (Intel i5-8365U / UHD 620)

{ config, pkgs, lib, inputs, ... }:

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
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;

  # ── Boot / Hibernation ────────────────────────────────────────────────────
  # disko declares cryptswap (see hosts/l390/disko-config.nix) and sets
  # resumeDevice = true on the swap content, so boot.resumeDevice is set
  # automatically. The mkForce below pins it explicitly in case other modules
  # also try to declare it.
  boot.resumeDevice = lib.mkForce "/dev/mapper/cryptswap";

  # ── Packages ──────────────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [

    # Desktop
    # waybar, rofi, mako installed by their home-manager modules
    # hypridle, hyprlock installed by programs.hyprlock / services.hypridle (modules/home/hyprlock.nix)
    cliphist
    awww
    brightnessctl
    kdePackages.polkit-kde-agent-1

    # Core utilities
    git
    wget
    curl
    unzip
    zip
    htop
    btop
    tree
    ripgrep
    fd
    jq
    fzf
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

    # Disk tools
    parted
    gparted
    ntfs3g
    exfatprogs

    # Terminal
    alacritty

    # Editors
    vscode
    neovim

    # Wayland
    wl-clipboard
    wl-clipboard-x11
    xdg-utils

    # Media
    playerctl
    pavucontrol
    inputs.nt-helper.packages.${pkgs.system}.default

    # Bluetooth
    blueman

    # Firmware updates
    fwupd

    # USB flasher
    popsicle
    papirus-icon-theme
    yt-dlp
    yewtube
    nh
  ];

  # ── Services ──────────────────────────────────────────────────────────────

  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;

  # ── Services ── mpd ──────────────────────────────────────────────────────

  services.mpd = {
    enable = true;
    user = "nimbus";
    settings = {
      music_directory = "/share/slsk/share";
      audio_output = [{
        type = "pipewire";
        name = "PipeWire";
      }];

      # Save state, so playlist/position survives restart
      auto_update = "yes";
      restore_paused = "yes";
      filesystem_charset = "UTF-8";
    };
    # default network setup is fine: localhost:6600
  };

  # MPD runs as a system service but needs to reach PipeWire's user socket
  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
  };

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
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
