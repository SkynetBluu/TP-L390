# CLAUDE.md — sandbox operating notes

You are running as the unprivileged `claude` user inside a NixOS sandbox; the
human is "nimbus".

## Environment

- Your work area is `/home/claude/workspace`.
- Projects live in `/home/claude/workspace/projects/` — these are bind-mounted
  from nimbus's space. You may edit files there; nimbus reviews and commits.
- The toolchain comes from a Nix devShell. `flake.nix`, `packages.nix`, etc.
  in the workspace are READ-ONLY — do not try to edit them. To request a
  permanent tool, see "Tool usage" below.
- You cannot use sudo, cannot become another user, and cannot reach nimbus's
  home directory. Do not attempt to work around it.

## Tool usage

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
- Your `~/.claude/` state (this file, settings, skills you build) persists but
  isn't auto-backed-up — see "Promoting changes" below to get anything worth
  keeping into the baseline.

## Promoting changes to the baseline

To get sandbox-side state (this file, `settings.json`, memory entries,
skills, etc.) into nimbus's permanent baseline:

1. Stage ONLY the files being promoted into
   `/home/claude/workspace/projects/promote-YYYY-MM-DD/`. Never blanket-copy
   `~/.claude/` — it holds credentials (`.credentials.json`), session
   history, and cache.
2. `chmod -R go+rX` the bundle so nimbus can read it.
3. From the nimbus host shell, drop the bundle in-place onto the baseline:

       cp -rT /home/nimbus/claude-projects/promote-YYYY-MM-DD \
              /home/nimbus/.config/nixos/claude-home

   Then `git diff` and commit from `/home/nimbus/.config/nixos/`.

## Subagents

Pick the model deliberately when spawning:

- **Haiku** — batch / repetitive work (summaries, classifying, parallel searches).
  Don't burn Opus tokens on these.
- **Sonnet** — search / locate / read-heavy work. The everyday default.
- **Opus** — only when the subagent itself must reason hard: architecture,
  design critique, second-opinion review.

When to delegate:
- Independent / parallelizable lookups (search A AND B AND C).
- Long, noisy explorations whose raw output would bloat my context.
- An independent second opinion I shouldn't do myself.

Skip subagents for: single known-file lookups, one-step fixes, or anything
where I already have enough context to just act.
