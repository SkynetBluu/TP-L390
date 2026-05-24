# claude-sandbox/flake.nix
# Reproducible toolchain for the claude sandbox user.
#
# This flake is nimbus-owned. The whole claude-sandbox/ directory is bind-
# mounted READ-ONLY into ~claude/workspace/claude-sandbox/ by
# modules/system/claude.nix, so claude can `nix develop` here but cannot
# alter its own toolchain. To change the toolchain, nimbus edits packages.nix
# and commits; the change flows in via the read-only mount (no rebuild needed
# for claude — just a fresh `nix develop`).
#
# Pin policy: nixpkgs is pinned by this flake's own flake.lock. `nix flake
# update` (run by nimbus) is the only thing that moves the toolchain version.
#
# claude-code-latest.nix lives in this directory (as a sibling of flake.nix)
# so that the system flake and the sandbox flake reuse the same file from
# one place, and so that pure-mode evaluation finds it under the flake root.

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
      # in exactly one place. The system flake imports the same file via
      # ./claude-sandbox/claude-code-latest.nix.
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
