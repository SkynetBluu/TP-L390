# modules/home/claude-launcher.nix
# Host-side launchers for the claude sandbox.
#
# Collapses `machinectl shell claude@` + `cd ~/workspace` + `nix develop -c
# claude` into a single command. Cwd is translated: if nimbus is inside
# ~/claude-projects/X, the launcher enters the sandbox at the matching
# /home/claude/workspace/projects/X (same files via the bind mount), so
# project context is preserved across the user boundary.
#
# Home-manager scope (not system): only nimbus has the polkit rule for
# password-free `machinectl shell claude@`, so anyone else running these
# would just get a polkit prompt.

{ pkgs, ... }:

let
  # Args from nimbus are forwarded to claude via bash's `-c CMD name args...`
  # form ($0 + $@), which avoids manually quoting arbitrary user input.
  claude-run = pkgs.writeShellScriptBin "claude-run" ''
    set -euo pipefail

    HOST_PROJECTS="$HOME/claude-projects"
    if [[ "$PWD" == "$HOST_PROJECTS" || "$PWD" == "$HOST_PROJECTS"/* ]]; then
      SUBPATH="''${PWD#$HOST_PROJECTS}"
      CLAUDE_DIR="/home/claude/workspace/projects$SUBPATH"
    else
      CLAUDE_DIR="/home/claude/workspace"
    fi

    exec ${pkgs.systemd}/bin/machinectl shell claude@ \
      /run/current-system/sw/bin/bash -lc \
      'cd "$0" && exec nix develop /home/claude/workspace/claude-sandbox -c claude "$@"' \
      "$CLAUDE_DIR" "$@"
  '';

  # `claude --continue` resumes the most recent session in the current
  # directory — which is why the cwd translation in claude-run is what makes
  # this useful from anywhere under ~/claude-projects.
  claude-resume = pkgs.writeShellScriptBin "claude-resume" ''
    exec ${claude-run}/bin/claude-run --continue "$@"
  '';
in
{
  home.packages = [
    claude-run
    claude-resume
  ];
}
