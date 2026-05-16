# modules/system/boot.nix
# Boot configuration — systemd-boot, LUKS, Btrfs initrd, hibernation

{ config, lib, pkgs, ... }:

{
  boot = {
    # ── Bootloader ────────────────────────────────────────────────────────
    loader = {
      systemd-boot = {
        enable             = true;
        configurationLimit = 5;
        consoleMode        = "auto";
      };
      efi.canTouchEfiVariables = true;
    };

    # ── Initrd ────────────────────────────────────────────────────────────
    # device / allowDiscards for cryptroot+cryptswap come from disko-config.nix.
    # availableKernelModules come from hardware-configuration.nix.
    # Only manual overrides live here.
    initrd = {
      systemd.enable = true;

      luks.devices.cryptroot = {
        bypassWorkqueues = true; # faster I/O; disko doesn't expose this option
      };
    };

    # ── Kernel ────────────────────────────────────────────────────────────
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [
      "kvm-intel" # Intel virtualisation
    ];

    kernelParams = [
      "quiet"
      "splash"
      "nowatchdog"
      "nmi_watchdog=0"
      "i915.enable_psr=1" # Intel Panel Self Refresh — saves power on battery
    ];

    # ── Plymouth ──────────────────────────────────────────────────────────
    plymouth = {
      enable = true;
      theme  = "bgrt"; # Shows Lenovo logo at boot
    };
  };
}
