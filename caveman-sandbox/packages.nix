# caveman-sandbox/packages.nix
# Locked toolchain for the caveman sandbox. nimbus-owned source of truth.
#
# Promotion flow mirrors claude-sandbox: caveman grabs one-offs with
# `nix shell nixpkgs#<tool>` and logs them; nimbus moves the useful ones here.
#
# caveman-code itself is NOT here — it's npm-installed into ~/.npm-global by
# devshell.nix's shellHook (pinned by version) until a proper nix derivation
# exists. Replace when ready.

{ pkgs }:

with pkgs; [
  # ── Language runtimes ─────────────────────────────────────────────────────
  nodejs_22          # caveman-code's runtime + npm for the bootstrap install
  python313
  uv

  # ── Nix tooling ───────────────────────────────────────────────────────────
  nix
  nil
  nixpkgs-fmt

  # ── direnv ────────────────────────────────────────────────────────────────
  # Also installed system-wide via programs.direnv in caveman.nix; listing them
  # here makes them available on the devShell's PATH when something invokes
  # `direnv` from a script (e.g. an editor's direnv integration).
  direnv
  nix-direnv

  # ── Version control ───────────────────────────────────────────────────────
  git

  # ── Search / inspection ───────────────────────────────────────────────────
  ripgrep
  fd
  jq
  tree

  # ── Network ───────────────────────────────────────────────────────────────
  curl
  wget

  # ── Embedded / bare-metal (STM32F411 and friends) ─────────────────────────
  # Promoted from projects/bare-metal-dev/flake.nix so every devShell that
  # inherits from this sandbox (via `inputsFrom`) gets the ARM toolchain
  # without redeclaring it. Keep here as long as bare-metal work is active;
  # demote back to a per-project flake if it goes dormant.
  gcc-arm-embedded   # arm-none-eabi-gcc/g++/gdb + newlib-nano
  gnumake
  stlink             # st-flash, st-info, st-util
  openocd            # alternative flash/debug + gdbserver
  minicom            # serial terminal for UART
  pulseview          # logic analyzer GUI
  sigrok-cli         # command-line captures
]
