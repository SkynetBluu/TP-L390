---
name: claude-shared permissions when nimbus copies files in
description: After nimbus cp's files into the bind-mounted project dirs, group inheritance is automatic via setgid + default ACL, but mode usually lands at 644 (group read-only) due to nimbus's umask. Claude can read but not write until chmod g+w.
type: reference
originSessionId: abae477d-c78f-4278-81e7-7f47033de78d
---
The bind-mounted project dirs under `/home/claude/workspace/projects/` (= `~nimbus/.../<project>/` on the host) have:

- Mode `drwxrws---` (setgid bit on group)
- Owner/group `nimbus:claude-shared`
- Default ACL: `default:group:claude-shared:r-x`

Effects when nimbus copies files in:

- Group is auto-set to `claude-shared` (setgid bit handles this — no `chgrp` needed)
- File mode usually lands at `644` (`-rw-r--r--`) due to nimbus's default `umask 022` — claude can read but not write
- Compare: files created by claude land at `-rw-rw----` (660) because claude's umask is 007

**Fix when claude needs write access:**

```sh
chmod -R g+w <files-or-dirs>    # on the host as nimbus
```

(Read-only inputs like fresh source PDFs don't need this.)

**Permanent fix:** set nimbus's `umask 002` (or 007) in `~nimbus/.bashrc` or `.zshrc` — new files come in as 664/660 automatically.

Diagnostic commands:

```sh
stat -c '%n  %U:%G  %A' <path>            # ownership + mode
getfacl <path>                            # ACL detail
```
