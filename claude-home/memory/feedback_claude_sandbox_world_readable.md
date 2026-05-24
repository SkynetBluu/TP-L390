---
name: Files in claude-sandbox/ must be world-readable
description: With the dir-bind setup, every file in nimbus's claude-sandbox/ source dir is exposed to claude through a read-only bind mount. nix develop pure-mode copies the WHOLE flake dir to /nix/store, so any file claude (uid 9000) can't read aborts the copy and breaks the devShell.
type: feedback
originSessionId: a8d20c7f-2d77-4016-8805-fe4985de1ec2
---
Any file added to `/home/nimbus/.config/nixos/claude-sandbox/` must be readable by `other` (i.e., world-readable, mode 644 / 755 / etc.). Otherwise `nix develop /home/claude/workspace/claude-sandbox` fails on first launch with an opaque-ish error from the pure-mode source copy step.

**Why:** Hit this on first launch after the dir-bind refactor — README.md was at mode 600 (nimbus's umask had set it that way before the dir bind existed; file binds never tried to read it). Fix was `sudo chmod 644 README.md`. The previous file-bind setup hid the problem because nix only ever evaluated the 4 explicitly-bound files, none of which had wrong perms.

**How to apply:** When I add a file to `nixos/claude-sandbox/` (via promote-nixos or otherwise), assume it needs to be 644 unless it's a script (755). If nimbus reports `nix develop` failing after promotion, suspect a permission bit first — `ls -la ~/.config/nixos/claude-sandbox/` from the host shell reveals it instantly. A future remedy worth considering: a tmpfiles rule or activation hook that chmod's the dir to a-rwX on rebuild, so this can't drift back.
