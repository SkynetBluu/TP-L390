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

  # Mesa pinned to Hyprland's flake input in modules/system/hyprland.nix
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
      # 75/80 matches "balanced" in battery-mode (modules/home/scripts.nix)
      # so the first Super+M press cycles to a different state.
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;

  # udev rules for ST-Link and Cypress chip (sigrok analyzer)
  services.udev.packages = [
    pkgs.sigrok-cli
  ];
  services.udev.extraRules = ''
    # ── ST-Link probes (we ship these ourselves instead of pkgs.stlink's
    # rules, because upstream uses MODE:="0666" which is := -locked and
    # can't be tightened from a higher-numbered rules file). ─────────────
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3744", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv1_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv2_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374a", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv2-1_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv2-1_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374d", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv3_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374e", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv3_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374f", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv3_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv3_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3753", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv3_%n"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3754", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="stlinkv3_%n"

    # ── fx2lafw logic analyzers (Cypress FX2 based) ──────────────────────
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04b4", ATTRS{idProduct}=="8613", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="608c", MODE="0660", GROUP="plugdev", TAG+="uaccess"
  
    # ── CH343 / CH340 USB-serial bridges (QinHeng) ─────────────────────
    SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d2", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="ttyCH343_%n"
    SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7522", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="ttyCH340_%n"
    SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="ttyCH340_%n"
  '';
  users.groups.plugdev = { };
  users.users.nimbus.extraGroups = [ "plugdev" ];
  # boot.resumeDevice is set automatically by disko (resumeDevice=true on the
  # swap content in hosts/l390/disko-config.nix).

  # ── Packages ──────────────────────────────────────────────────────────────

  # System-wide packages: things that must work pre-login / from a TTY /
  # in root contexts. User-facing tools with home-manager config live in
  # modules/home/.
  environment.systemPackages = with pkgs; [
    # Desktop daemons
    cliphist
    awww
    brightnessctl

    # Core utilities
    git
    wget
    curl
    htop
    vim
    nano
    ncdu

    # Hardware
    pciutils
    usbutils
    lshw
    smartmontools
    powertop
    nvme-cli
    stlink

    # Btrfs
    btrfs-progs
    compsize

    # Networking
    networkmanagerapplet

    # Disk-rescue set
    parted
    gparted
    ntfs3g
    exfatprogs

    # Editors (fallback; primary configs in modules/home/)
    vscode
    neovim

    # Wayland
    xdg-utils

    # Media
    playerctl
    pavucontrol
    inputs.nt-helper.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Bluetooth
    blueman

    # Firmware
    fwupd

    # Nix helper
    nh
  ];

  # ── Services ──────────────────────────────────────────────────────────────

  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;
  services.upower.enable = true; # consumed by waybar battery + perf-mode-daemon

  # Needed for nemo (and other GTK apps) to persist settings
  programs.dconf.enable = true;

  # MPD runs as a user service via modules/home/mpd.nix

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
  # Both intentionally OFF. Snapshots on the same disk are not a backup —
  # they protect against mistakes, not hardware failure.
  #
  # Scrub surfaces silent bit-rot (can't repair without redundancy):
  #   services.btrfs.autoScrub = {
  #     enable = true;
  #     interval = "monthly";
  #     fileSystems = [ "/" ];
  #   };
  #
  # Snapper on /home only (NixOS generations cover @; @nix is GC-managed):
  #   services.snapper.configs.home = {
  #     SUBVOLUME = "/home";
  #     ALLOW_USERS = [ "nimbus" ];
  #     TIMELINE_CREATE = true;
  #     TIMELINE_CLEANUP = true;
  #     TIMELINE_LIMIT_HOURLY = 5;
  #     TIMELINE_LIMIT_DAILY = 7;
  #     TIMELINE_LIMIT_WEEKLY = 4;
  #     TIMELINE_LIMIT_MONTHLY = 3;
  #     TIMELINE_LIMIT_YEARLY = 0;
  #   };

  # ── Secrets (sops-nix) ────────────────────────────────────────────────────
  # Wire up after first boot, once /etc/ssh/ssh_host_ed25519_key exists:
  #   sops = {
  #     defaultSopsFile = ./secrets/secrets.yaml;
  #     age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  #   };

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
