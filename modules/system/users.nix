# modules/system/users.nix
# User accounts

{ config, pkgs, ... }:

{
  users.users.nimbus = {
    isNormalUser = true;
    description = "Nimbus";
    shell = pkgs.bash; # Change to pkgs.zsh or pkgs.fish if preferred
    extraGroups = [
      "wheel"          # sudo access
      "networkmanager" # manage Wi-Fi without sudo
      "video"          # screen brightness (brightnessctl)
      "audio"          # audio devices
      "input"          # input devices
    ];
  };

  # Disable root login — use sudo instead
  users.users.root.hashedPassword = "!";
}
