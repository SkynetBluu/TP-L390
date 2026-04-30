# modules/system/networking.nix
# Network configuration — NetworkManager, Wi-Fi, firewall

{ config, pkgs, ... }:

{
  networking = {
    # NetworkManager handles Wi-Fi and ethernet
    networkmanager.enable = true;

    # Basic firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  # DNS — use systemd-resolved with DNSSEC
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = [
      "9.9.9.9"       # Quad9
      "149.112.112.112"
      "2620:fe::fe"
    ];
  };
}
