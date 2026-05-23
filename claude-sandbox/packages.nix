# claude-sandbox/packages.nix
# The locked toolchain for the claude sandbox. nimbus-owned source of truth.
#
# This is the ONLY place tools are permanently added. Claude grabs one-off
# tools with `nix shell nixpkgs#<tool>` (ephemeral) and logs them; nimbus
# promotes the useful ones here, then commits. Version is pinned by the
# flake's flake.lock — `nix flake update` (nimbus) moves it.

{ pkgs }:

with pkgs; [
  # ── The agent itself ──────────────────────────────────────────────────────
  claude-code

  # ── Language runtimes ─────────────────────────────────────────────────────
  nodejs_22          # claude-code's runtime
  python313
  uv

  # ── Nix tooling ───────────────────────────────────────────────────────────
  nix                # so claude can `nix shell`, `nix develop`, etc.
  nil                # nix language server
  nixpkgs-fmt

  # ── Version control (claude needs git; identity wired later) ──────────────
  git

  # ── Search / inspection ───────────────────────────────────────────────────
  ripgrep
  fd
  jq
  tree

  # ── Network ───────────────────────────────────────────────────────────────
  curl
  wget
]
