# AGENTS.md — caveman sandbox operating notes

You are running as the unprivileged `caveman` user inside a NixOS sandbox; the
human is "nimbus". This is the global instruction file at `~/.cave/AGENTS.md`
(caveman's resource-loader picks `AGENTS.md` over `CLAUDE.md` when both exist).

## Environment

- Your work area is `/home/caveman/workspace`.
- Projects live in `/home/caveman/workspace/projects/` — these are bind-mounted
  from nimbus's space (`~nimbus/caveman-projects/`). You may edit files there;
  nimbus reviews and commits.
- The toolchain comes from a Nix devShell at
  `/home/caveman/workspace/caveman-sandbox/`, auto-activated by direnv when
  you `cd ~/workspace`. That whole directory is READ-ONLY — do not try to
  edit anything there. To request a permanent tool, see "Tool usage" below.
- You cannot use sudo, cannot become another user, cannot reach `~nimbus/`,
  and cannot see into `~claude/` (a separate sandbox user). Do not attempt
  to work around any of this.

## direnv

The toolchain auto-loads via direnv when you enter `~/workspace`. The first
time you ever enter (or whenever the `.envrc` content changes), direnv will
refuse to activate until you run:

    direnv allow

This is a security gate, not a misconfiguration. Run it once, then forget about
it. If a `direnv: error .envrc is blocked` message appears, the cause is a
content bump from nimbus — re-run `direnv allow` and continue.

## Tool usage

If you need a tool that isn't already available, get it ad-hoc with:

    nix shell nixpkgs#<tool> --command <tool> ...

This is ephemeral (it lasts only for that command/subshell). Do NOT edit
`caveman-sandbox/packages.nix` or try to install tools permanently — you
can't, and shouldn't.

**Whenever you reach for a tool via `nix shell`, append a line to
`/home/caveman/workspace/tool-usage.log`** in this format:

    YYYY-MM-DD  <tool>  <one-line reason>

For example:

    2026-05-23  jq  parsing API response in projects/foo

This log is how nimbus decides which tools to promote into the permanent
toolchain. Keep it honest and current.

## Caveman config

- Settings live in `~/.cave/settings.json`.
- Commands: `~/.cave/commands/*.md`.
- Skills: `~/.cave/skills/<name>/SKILL.md`.
- Subagents: `~/.cave/agents/<name>.md`.
- Memory (cavemem): `~/.cave/memory/MEMORY.md` (auto-injected each turn).
- MCP servers: project-local `.mcp.json` (same path as Claude Code).

Caveman runs in autopilot — no permission prompts before edits or shell calls.
That's the product, not a bug. The sandbox boundary is the uid wall, not an
in-process approval gate. Behave accordingly: when you reach for `rm -rf` or
`git push --force`, the safeguard is *you*.

## Working style

- Prefer working inside a project directory under `workspace/projects/`.
- Use git for anything you want to be durable; commit your work in the project
  repo as you go.
- Your `~/.cave/` state (this file, settings, skills you build) persists but
  isn't auto-backed-up — see "Promoting changes" below to get anything worth
  keeping into the baseline.

## Promoting changes to the baseline

Run inside the sandbox; the script prints the exact copy-paste command for
nimbus to run on the host.

- **`promote-caveman-home`** — bundles your live `~/.cave/{AGENTS.md,
  settings.json, memory, skills, commands, agents}` for nimbus to overlay
  onto `~/.config/nixos/caveman-home/`. The allowlist deliberately excludes
  credentials, sessions, history, cache.

- **`promote-nixos`** — bundles worktree changes in
  `~/workspace/projects/my-conf/nixos/` for nimbus to overlay onto
  `~/.config/nixos/`. Handles adds, modifies, and deletions (emits
  `cp -rT` + `git add` + `git rm` in the printed host one-liner). Same
  script as the claude side, run as a different user.

Per-machine state (`~/.netrc`, anything else with secrets) is NEVER in the
bundle's allowlist — nimbus copies it in by hand once per machine.
