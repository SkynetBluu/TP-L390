---
name: The `!` prefix runs inside the sandbox, not on the host
description: When Claude Code is launched inside the machinectl sandbox, `!`-prefixed commands run as the sandboxed claude user — same blast radius as my Bash tool. They cannot reach ~nimbus/ or anything else outside the sandbox. Don't suggest `!` for host-side work.
type: feedback
originSessionId: a8d20c7f-2d77-4016-8805-fe4985de1ec2
---
When Claude Code is running inside the claude sandbox, the `!` prefix executes in *this* session's shell, which is the unprivileged claude user — exactly the same scope as my Bash tool. It is NOT a back-door to nimbus's shell.

**Why:** I suggested `! cp ~/claude-projects/... ~/.config/nixos/...` to land a promote bundle. The user (correctly) pushed back: that would have run as claude inside the sandbox and failed on `~nimbus/` (mode 0700). The general session-guidance about `!` for "user-runs-it" commands assumes Claude is running on the host; in this sandboxed setup that assumption is inverted.

**How to apply:** For anything that touches `/home/nimbus/`, `~/.config/nixos/`, `sudo`, `nixos-rebuild`, or otherwise needs host privileges, tell nimbus the exact command to run in a host shell as themselves — no `!` prefix. The `!` is only useful for commands I could run via Bash but choose not to (e.g., I want their interactive prompt to handle auth). In this sandbox, those cases are rare.
