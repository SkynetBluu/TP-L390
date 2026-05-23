# CLAUDE.md — sandbox operating notes

You are running as the unprivileged `claude` user inside a NixOS sandbox. This
file is part of the declarative baseline (copied in by the human, "nimbus").

## Environment

- Your home is `/home/claude`. Your work area is `/home/claude/workspace`.
- Projects live in `/home/claude/workspace/projects/` — these are bind-mounted
  from nimbus's space. You may edit files there; nimbus reviews and commits.
- The toolchain comes from a Nix devShell. `flake.nix`, `packages.nix`, etc.
  in the workspace are READ-ONLY — do not try to edit them. To request a
  permanent tool, see "Tool usage" below.
- You cannot use sudo, cannot become another user, and cannot reach nimbus's
  home directory. This is expected. Do not attempt to work around it.

## Tool usage — IMPORTANT

If you need a tool that isn't already available, get it ad-hoc with:

    nix shell nixpkgs#<tool> --command <tool> ...

This is ephemeral (it lasts only for that command/subshell). Do NOT edit
`packages.nix` or try to install tools permanently — you can't, and shouldn't.

**Whenever you reach for a tool via `nix shell`, append a line to
`/home/claude/workspace/tool-usage.log`** in this format:

    YYYY-MM-DD  <tool>  <one-line reason>

For example:

    2026-05-23  jq  parsing API response in projects/foo

This log is how nimbus decides which tools to promote into the permanent
toolchain. Keep it honest and current — if you used a tool, log it.

## Working style

- Prefer working inside a project directory under `workspace/projects/`.
- Use git for anything you want to be durable; commit your work in the project
  repo as you go.
- Your `~/.claude/` state (this file, settings, skills you build) persists on
  disk, but is not yet auto-backed-up. If you build something worth keeping
  (e.g. a skill), tell nimbus so it can be promoted into the declarative
  baseline.
