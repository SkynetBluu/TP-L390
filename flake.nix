{
  description = "NixOS configuration for ThinkPad L390 (Intel i5-8365U)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware profiles — lenovo-thinkpad-x390 is closest match for L390
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland — official flake for latest stable
    hyprland.url = "github:hyprwm/Hyprland";

    # Encrypted secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, disko, hyprland, sops-nix, ... } @ inputs:
    let
      system = "x86_64-linux";

      # Shared overlays
      sharedOverlays = [
        # Claude Code — latest prebuilt binary from npm
        (final: prev: {
          claude-code = import ./overlays/claude-code-latest.nix {
            inherit (prev) lib fetchurl claude-code patchelf glibc stdenv;
          };
        })
      ];

      specialArgs = {
        inherit inputs;
      };
    in
    {
      nixosConfigurations.l390 = nixpkgs.lib.nixosSystem {
        inherit specialArgs;

        modules = [
          # nixpkgs settings
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = sharedOverlays;
          }

          # Declarative disk partitioning
          disko.nixosModules.disko
          ./hosts/l390/disko-config.nix

          # Auto-generated hardware config (run nixos-generate-config after disko)
          ./hosts/l390/hardware-configuration.nix

          # ThinkPad X390 hardware profile — best match for L390
          nixos-hardware.nixosModules.lenovo-thinkpad-x390

          # Main system configuration
          ./hosts/l390/configuration.nix

          # System modules
          ./modules/system/boot.nix
          ./modules/system/networking.nix
          ./modules/system/hyprland.nix
          ./modules/system/sound.nix
          ./modules/system/locale.nix
          ./modules/system/users.nix
          ./modules/system/fonts.nix
          ./modules/system/security.nix

          # Secrets management
          sops-nix.nixosModules.sops

          # Home Manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs      = true;
            home-manager.useUserPackages    = true;
            home-manager.extraSpecialArgs   = specialArgs // { theme = import ./modules/home/theme.nix; };
            home-manager.backupFileExtension = "backup";
            home-manager.users.nimbus       = import ./modules/home/home.nix;
          }
        ];
      };
    };
}
