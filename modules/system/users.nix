# modules/system/users.nix
# User accounts

{ config, pkgs, ... }:

{
  users.users.nimbus = {
    isNormalUser = true;
    description = "Nimbus";
    shell = pkgs.bash; # Change to pkgs.zsh or pkgs.fish if preferred
    extraGroups = [
      "wheel" # sudo access
      "networkmanager" # manage Wi-Fi without sudo
      "video" # screen brightness (brightnessctl)
      # audio: redundant under PipeWire + RTKit
      # input: gives raw /dev/input/* access; not needed with logind/seat handling
    ];
  };

  # Disable root login — use sudo instead
  users.users.root.hashedPassword = "!";
}
