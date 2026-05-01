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
  # After install, verify UUID: blkid /dev/sda3
  # Update to: boot.resumeDevice = "/dev/disk/by-uuid/YOUR-UUID";
  boot.resumeDevice = lib.mkForce "/dev/mapper/cryptswap";

  # ── Packages ──────────────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [

    # Desktop
    waybar
    rofi
    cliphist
    awww
    mako
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

    # Claude Code — from overlay

    # Wayland
    wl-clipboard
    wl-clipboard-x11
    xdg-utils

    # Media
    playerctl
    pavucontrol

    # Bluetooth
    blueman

    # Firmware updates
    fwupd

    # USB flasher
    popsicle
    papirus-icon-theme
    hypridle
    hyprlock
    yt-dlp
    yewtube
    nh
  ];

  # ── Services ──────────────────────────────────────────────────────────────

  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;

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
