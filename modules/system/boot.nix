# modules/system/boot.nix
# Boot configuration — systemd-boot, LUKS, Btrfs initrd, hibernation

{ config, pkgs, ... }:

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
    initrd = {
      systemd.enable = true;

      availableKernelModules = [
        "xhci_pci"    # USB 3.0
        "ahci"        # SATA
        "usb_storage" # USB storage
        "sd_mod"      # SCSI disk
      ];

      luks.devices = {
        cryptroot = {
          device           = "/dev/disk/by-partlabel/root";
          allowDiscards    = true;
          bypassWorkqueues = true;
        };
        cryptswap = {
          device        = "/dev/disk/by-partlabel/swap";
          allowDiscards = true;
        };
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
