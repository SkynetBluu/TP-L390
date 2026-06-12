---
name: Nix pure-mode flake eval can't read across flake boundaries
description: Symlinks pointing outside a flake's source tree resolve to dead store paths during pure eval — don't use them to share files between sibling flakes.
type: feedback
originSessionId: 320645da-a37f-4ef6-885b-e466dc777dfc
---
A symlink inside one flake's source tree pointing to a file in a sibling
flake's tree (e.g., `caveman-sandbox/promote-nixos -> ../claude-sandbox/promote-nixos`)
fails at `nix develop` time with:

    error: access to absolute path '/nix/store/claude-sandbox/promote-nixos'
    is forbidden in pure evaluation mode

Why: Nix copies each flake's source tree independently into the store. The
symlink target `../claude-sandbox/...` resolves from inside
`/nix/store/HASH-caveman-sandbox/` to `/nix/store/claude-sandbox/...`, which
doesn't exist. Pure-mode then forbids reading anything outside the flake's
own store path.

How to apply: when sharing scripts/files between sibling flakes, pick one:
1. **Copy with a sync note** — fastest, accept manual drift risk. Add a
   "DUPLICATE: keep byte-identical with X" header in both files. We did this
   for promote-nixos across claude-sandbox/ and caveman-sandbox/.
2. **Flake input** — declare the other flake's path as a `path:` input. Single
   source of truth, but requires `nix flake update` after every edit to refresh
   the lock.
3. **Hoist to a shared sibling** — move the file to a third dir referenced as
   a flake input from both. Architecturally cleanest, most refactoring.

Same applies to `builtins.readFile` on a path outside the flake — also blocked.
