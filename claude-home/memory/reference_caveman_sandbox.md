---
name: Caveman sandbox (sibling to claude)
description: A second isolated sandbox user `caveman` (uid 9001) runs the caveman-code agent, separate from this `claude` sandbox.
type: reference
originSessionId: 320645da-a37f-4ef6-885b-e466dc777dfc
---
Nimbus runs a second sandbox alongside this one, for the caveman-code agent:

- User: `caveman`, uid 9001, group `caveman` (gid 9001), bridge group
  `caveman-shared` (nimbus + caveman; claude is deliberately NOT a member —
  the two sandboxes can't see each other).
- Home: `/home/caveman/`, 0750 caveman:caveman-shared.
- Projects bind: `~nimbus/caveman-projects/` → `/home/caveman/workspace/projects/` RW.
- Toolchain: `nixos/caveman-sandbox/` flake, bind-mounted RO into
  `/home/caveman/workspace/caveman-sandbox/`, auto-activated by direnv on
  `cd ~/workspace` (system-wide `programs.direnv` with nix-direnv).
- Config dir: `~/.cave/` (not `~/.claude/`).
- Agent instruction file: `AGENTS.md` (loader picks it ahead of `CLAUDE.md`),
  not the Claude Code naming.
- Promote scripts mirror the claude side: `promote-caveman-home` and a
  byte-identical `promote-nixos` copy. Sync note in both promote-nixos
  headers — keep them identical when editing.

How to apply:
- When asked "isolate this other agent too", point to the caveman pattern
  rather than re-deriving it. Add a third sandbox by cloning caveman.nix.
- When discussing agent state or config paths, remember caveman uses
  `~/.cave/`, AGENTS.md, and has no permission system (autopilot by design).
- I (claude, uid 9000) cannot reach `/home/caveman/` — uid wall. To write
  anything there, instruct nimbus.
