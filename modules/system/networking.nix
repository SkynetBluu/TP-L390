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
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      Domains = [ "~." ];
      FallbackDNS = [
	"9.9.9.9"
	"149.112.112.112"
	"2620:fe::fe"
      ];
    };
  };
}
