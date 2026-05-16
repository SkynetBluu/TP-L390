# modules/system/networking.nix
# Network configuration — NetworkManager, Wi-Fi, firewall

{ config, pkgs, ... }:

{
  networking = {
    # NetworkManager handles Wi-Fi and ethernet
    networkmanager = {
      enable = true;
      # Push per-link DNS into systemd-resolved (instead of NM writing its own
      # resolv.conf). Without this the DNSSEC chain below is partly bypassed.
      dns = "systemd-resolved";
    };

    # Basic firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  # DNS — use systemd-resolved with DNSSEC + opportunistic DoT
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic"; # encrypt to FallbackDNS / per-link DNS when supported
      Domains = [ "~." ];
      FallbackDNS = [
        "9.9.9.9"          # Quad9 primary IPv4
        "149.112.112.112"  # Quad9 secondary IPv4
        "2620:fe::fe"      # Quad9 primary IPv6
      ];
    };
  };
}
