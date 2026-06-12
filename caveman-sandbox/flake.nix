# caveman-sandbox/flake.nix
# Reproducible toolchain for the caveman sandbox user. Mirrors claude-sandbox/.
#
# nimbus-owned. The whole directory is bind-mounted RO into
# ~caveman/workspace/caveman-sandbox/ by modules/system/caveman.nix.
#
# Direnv entry: workspace-root .envrc is bind-mounted from this directory's
# ./.envrc and calls `use flake ./caveman-sandbox`, so `cd ~/workspace` loads
# the devShell automatically.
#
# Pin policy: nixpkgs is pinned by this flake's own flake.lock. `nix flake
# update` (run by nimbus) is the only thing that moves the toolchain version.
#
# No overlay here — caveman-code is not in nixpkgs. devshell.nix npm-installs
# it into ~/.npm-global on first entry, pinned by version. Replace with a
# proper derivation when one exists; drop the bootstrap from devshell.nix.

{
  description = "Reproducible toolchain for the Caveman Code sandbox user";

  inputs = {
    # Same channel as the system flake (and claude-sandbox) for cache hits.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      devShells.${system} = rec {
        default = import ./devshell.nix { inherit pkgs; };
        caveman = default;
      };
    };
}
