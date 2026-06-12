---
name: direnv reload fails when .envrc is RO bind-mounted
description: `direnv reload` calls chtimes on .envrc to invalidate cache, fails on RO mounts — nuke .direnv and re-cd instead.
type: feedback
originSessionId: 320645da-a37f-4ef6-885b-e466dc777dfc
---
When `.envrc` is bind-mounted read-only (e.g., from a nimbus-owned source dir
into a sandbox user's workspace), `direnv reload` fails with:

    direnv: error chtimes /home/<user>/workspace/.envrc: read-only file system

Because direnv updates the .envrc's mtime to force a re-eval, and the RO
bind mount blocks the write.

Workaround — nuke the cache directly and re-trigger the load with a `cd`:

    rm -rf ~/workspace/.direnv
    cd ~ && cd workspace

Direnv re-evaluates from scratch, hits the bootstrap path, all is well.

How to apply:
- Don't suggest `direnv reload` to a user inside the claude or caveman
  sandbox after a flake/devshell bump — it'll fail.
- After nimbus changes the source-side .envrc / flake / devshell.nix /
  packages.nix, the sandbox-side cache is invalidated by content hash on the
  next `cd` automatically; usually no manual step needed unless cached
  state is poisoned.
- Only the `.direnv/`-nuke recipe forces a clean re-eval mid-session.
