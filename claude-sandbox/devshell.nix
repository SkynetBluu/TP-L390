# claude-sandbox/devshell.nix
# The shell environment for the claude user. nimbus-owned and load-bearing:
# env vars, shellHook, and the structural bits live here. The *package list*
# is split into ./packages.nix to keep this file stable.
#
# Ad-hoc tools: claude does NOT edit this file to add tools. Instead it runs
#   nix shell nixpkgs#<tool>
# for one-off needs, and records what it reached for in its activity log (see
# claude-home/CLAUDE.md). nimbus periodically promotes useful tools into
# packages.nix. This keeps packages.nix the single, locked source of truth.

{ pkgs }:

pkgs.mkShell {
  packages = (import ./packages.nix { inherit pkgs; })
    ++ (import ./scripts.nix { inherit pkgs; });

  shellHook = ''
    # Pin claude's home explicitly. Under `machinectl shell claude@` this is
    # already /home/claude, but set it so behaviour is identical if the shell
    # is entered another way.
    export CLAUDE_WORKSPACE="$HOME/workspace"

    # Disable claude-code's in-process auto-updater. Otherwise it writes into
    # ~/.local/share/claude/versions/ and shadows the Nix-provided binary on
    # the next launch, breaking reproducibility.
    export DISABLE_AUTOUPDATER=1
    export DISABLE_UPDATES=1
    export CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=false

    # Long Nix builds between turns shouldn't time out the Bash tool.
    export BASH_DEFAULT_TIMEOUT_MS=60000
    export BASH_MAX_TIMEOUT_MS=600000

    # 1h system-prompt cache (default 5min) — worth it when build steps
    # between turns regularly exceed the default window.
    export ENABLE_PROMPT_CACHING_1H=1

    # Point ad-hoc `nix shell nixpkgs#...` at THIS flake's pinned nixpkgs, so
    # tools claude grabs on the fly come from the same locked revision as the
    # core toolchain (reproducible-ish, not floating with a channel).
    export NIX_PATH="nixpkgs=${pkgs.path}"

    if [ -t 1 ]; then
      echo "claude sandbox — node $(${pkgs.nodejs_22}/bin/node --version), $(claude --version 2>/dev/null || echo 'claude-code')"
      echo "workspace: $CLAUDE_WORKSPACE   projects: $CLAUDE_WORKSPACE/projects"
    fi
  '';
}
