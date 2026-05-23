# claude-sandbox/flake.nix
# Reproducible toolchain for the claude sandbox user.
#
# This flake is nimbus-owned. flake.nix / flake.lock / devshell.nix /
# packages.nix are bind-mounted READ-ONLY into ~claude/workspace/ by
# modules/system/claude.nix, so claude can `nix develop` here but cannot
# alter its own toolchain. To change the toolchain, nimbus edits packages.nix
# and commits; the change flows in via the read-only mount (no rebuild needed
# for claude — just a fresh `nix develop`).
#
# Pin policy: nixpkgs is pinned by this flake's own flake.lock. `nix flake
# update` (run by nimbus) is the only thing that moves the toolchain version.
#
# claude-code itself comes from the same overlay nimbus's system uses, so the
# CLI version is controlled in one place (../overlays/claude-code-latest.nix).

{
  description = "Reproducible toolchain for the Claude sandbox user";

  inputs = {
    # Keep this on the same channel as the system flake for cache hits.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      # Reuse the system's claude-code overlay so the CLI version is defined
      # in exactly one place. modules/system/claude.nix bind-mounts the file
      # from ../overlays/claude-code-latest.nix into claude's workspace as a
      # sibling of this flake — referencing it via a local-relative path so
      # pure-mode evaluation (which copies the workspace to /nix/store) works.
      claudeCodeOverlay = final: prev: {
        claude-code = import ./claude-code-latest.nix {
          inherit (prev) lib fetchurl claude-code patchelf glibc stdenv;
        };
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ claudeCodeOverlay ];
      };
    in
    {
      devShells.${system} = rec {
        default = import ./devshell.nix { inherit pkgs; };
        # Also expose under an explicit name for clarity / `nix develop .#claude`.
        claude = default;
      };
    };
}
