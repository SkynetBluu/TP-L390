# caveman-sandbox/devshell.nix
# Shell environment for the caveman user. nimbus-owned and load-bearing.
# Package list lives in packages.nix.
#
# Entry: invoked by direnv via `use flake` on `cd ~/workspace`. nix-direnv
# caches the realisation per .envrc hash, so the shellHook only runs again
# when packages.nix or this file changes (i.e. when nimbus bumps the toolchain).
#
# Ad-hoc tools: caveman runs `nix shell nixpkgs#<tool>` for one-offs and logs
# the reach into ~/workspace/tool-usage.log. nimbus periodically promotes the
# useful ones into packages.nix.

{ pkgs }:

let
  # Pin the caveman-code CLI here. Bump explicitly when you want a newer
  # version; caveman picks it up on the next direnv reload.
  cavemanVersion = "0.65.2";
in
pkgs.mkShell {
  packages = (import ./packages.nix { inherit pkgs; })
    ++ (import ./scripts.nix { inherit pkgs; });

  shellHook = ''
    export CAVEMAN_WORKSPACE="$HOME/workspace"

    # caveman-code is npm-only for now. Lands in ~/.npm-global so the install
    # stays in caveman's home (the nix store is read-only). Reproducibility is
    # best-effort: the version is pinned, but resolved by npm against whatever
    # the registry returns. Replace with a derivation when one exists.
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

    # Reinstall when the binary is missing OR the installed version drifts
    # from the pin above (so bumping cavemanVersion in this file triggers
    # an install on next direnv reload).
    _cave_installed="$(caveman --version 2>/dev/null | ${pkgs.gnused}/bin/sed -n 's/^[^0-9]*\([0-9][0-9.]*\).*/\1/p')"
    if [ "$_cave_installed" != "${cavemanVersion}" ]; then
      echo "caveman: installing @juliusbrussee/caveman-code@${cavemanVersion} → $NPM_CONFIG_PREFIX (was: ''${_cave_installed:-none})…"
      mkdir -p "$NPM_CONFIG_PREFIX"
      npm install -g "@juliusbrussee/caveman-code@${cavemanVersion}" >/dev/null
    fi
    unset _cave_installed

    # Caveman config dir — default is ~/.cave; set explicitly so behaviour is
    # identical regardless of how the shell is entered.
    export CAVE_CODING_AGENT_DIR="$HOME/.cave"

    # Extended prompt cache (caveman honours the Claude-Code-style flag).
    export CAVE_CACHE_RETENTION=long

    # Long Nix builds between turns shouldn't time out the Bash tool.
    export BASH_DEFAULT_TIMEOUT_MS=60000
    export BASH_MAX_TIMEOUT_MS=600000

    # Point ad-hoc `nix shell nixpkgs#...` at THIS flake's pinned nixpkgs.
    export NIX_PATH="nixpkgs=${pkgs.path}"

    # Banner only on direct `nix develop`, not on every direnv reload.
    if [ -t 1 ] && [ -z "$DIRENV_DIR" ]; then
      echo "caveman sandbox — node $(${pkgs.nodejs_22}/bin/node --version), $(caveman --version 2>/dev/null || echo 'not installed')"
      echo "workspace: $CAVEMAN_WORKSPACE   projects: $CAVEMAN_WORKSPACE/projects"
    fi
  '';
}
