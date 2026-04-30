# disko-config.nix
# Declarative disk partitioning for ThinkPad L390
# Layout:
#   /dev/sda1  —  1MB        BIOS boot gap (GPT compat)
#   /dev/sda2  —  512MB      EFI system partition (fat32, /boot)
#   /dev/sda3  —  16GB       Swap (inside LUKS)
#   /dev/sda4  —  ~449GB     Root (LUKS → Btrfs subvolumes)
#
# Btrfs subvolumes:
#   @            →  /
#   @home        →  /home
#   @nix         →  /nix
#   @snapshots   →  /.snapshots
#   @log         →  /var/log   (excluded from root snapshots)
#
# To apply during install:
#   sudo nix run github:nix-community/disko -- --mode disko /path/to/disko-config.nix

{ ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {

            # BIOS boot gap — required for GPT on some firmware
            bios = {
              size = "1M";
              type = "EF02";
              priority = 1;
            };

            # EFI system partition — unencrypted, holds systemd-boot
            ESP = {
              size = "512M";
              type = "EF00";
              priority = 2;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            # Swap partition inside LUKS
            # 16GB — matches RAM for full hibernation support
            
	    swap = {
	      size = "16G";
	      priority = 3;
	      content = {
		type = "luks";
		name = "cryptswap";
		settings = {
		  allowDiscards = true;
		};
		content = {
		  type = "swap";
		  resumeDevice = true;
		};
	      };
	    };


            # Root partition — LUKS encrypted Btrfs
            root = {
              size = "100%";
              priority = 4;
              content = {
                type = "luks";
                name = "cryptroot";
                # Passphrase will be prompted during disko run
                settings = {
                  allowDiscards = true; # SSD TRIM support
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-L" "nixos" "-f" ];
                  subvolumes = {

                    # Root subvolume
                    "@" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"   # Transparent compression (~25% space saving)
                        "noatime"         # Don't update access times — better SSD performance
                        "discard=async"   # Async TRIM for SSD
                      ];
                    };

                    # Home — separate so root rollbacks don't affect user data
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "discard=async"
                      ];
                    };

                    # Nix store — never snapshot this, it's large and managed by Nix
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "discard=async"
                      ];
                    };

                    # Snapshots
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                    # Logs — kept outside root snapshots so logs survive rollbacks
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                  };
                };
              };
            };

          };
        };
      };
    };
  };
}
