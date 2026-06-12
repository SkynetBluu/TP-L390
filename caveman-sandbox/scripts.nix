# caveman-sandbox/scripts.nix
# Sandbox-internal helper scripts, written onto PATH inside the devShell.
# Mirrors claude-sandbox/scripts.nix. The bash sources live alongside this
# file as plain executable scripts so they can be edited and tested
# standalone; readFile inlines them at evaluation time (no Nix-string
# escaping of bash ${...}).
#
# `promote-nixos` is byte-identical to claude-sandbox/promote-nixos. A symlink
# would be cleaner but each sandbox is its own flake and pure-mode eval can't
# read across flake boundaries. Keep the two files in sync by hand — see the
# DUPLICATE note in either header.

{ pkgs }:

[
  (pkgs.writeShellScriptBin "promote-caveman-home"
    (builtins.readFile ./promote-caveman-home))

  (pkgs.writeShellScriptBin "promote-nixos"
    (builtins.readFile ./promote-nixos))
]
