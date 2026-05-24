# claude-sandbox/scripts.nix
# Sandbox-internal helper scripts, written onto PATH inside the devShell.
# The bash sources live alongside this file as plain executable scripts so
# they can be edited and tested standalone; readFile inlines them at
# evaluation time, which also means no Nix-string escaping of bash ${...}.

{ pkgs }:

[
  (pkgs.writeShellScriptBin "promote-nixos"
    (builtins.readFile ./promote-nixos))

  (pkgs.writeShellScriptBin "promote-claude-home"
    (builtins.readFile ./promote-claude-home))
]
