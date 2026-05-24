# Claude sandbox — declarative, reproducible, isolated

A dedicated `claude` user (uid 9000) gives kernel-enforced separation from
`nimbus`. Entry is via `machinectl shell claude@` (clean logind session — no
inherited `$DISPLAY`, Wayland socket, or dbus bus). The toolchain is a pinned
Nix devShell, bind-mounted read-only into claude's workspace. Projects are a
nimbus-owned directory bind-mounted read-write. Home state is managed by hand.

```
/home/nimbus/.config/nixos/
├── claude-sandbox/              # nimbus-owned; whole dir bind-mounted RO into claude
│   ├── flake.nix
│   ├── flake.lock               # generated on first `nix flake lock` (see setup)
│   ├── devshell.nix             # env + shellHook (load-bearing)
│   ├── packages.nix             # the locked toolchain — single source of truth
│   ├── scripts.nix              # sandbox-internal helpers on PATH in the devShell
│   ├── promote-nixos            # sandbox → host bundling script (bash source)
│   ├── promote-claude-home      # same, for the claude-home baseline
│   └── claude-code-latest.nix   # the claude-code overlay (also imported by system flake)
├── claude-home/                 # Tier 1 baseline; copied by hand into ~claude/.claude
│   ├── CLAUDE.md
│   └── settings.json
└── modules/system/claude.nix    # the user, group, perms, polkit, mounts

/home/nimbus/claude-projects/    # nimbus owns; bind-mounted RW -> claude workspace
/home/claude/                    # claude:claude-shared 0750 (nimbus can read)
└── workspace/
    ├── claude-sandbox/          # RO dir bind mount of nimbus's claude-sandbox/
    ├── projects/                # RW bind mount
    └── tool-usage.log           # claude's wishlist
```

## Integration into your flake

`claude-sandbox/` is a **separate flake** for the devShell, but the
`claude.nix` *module* must be added to your system flake. Two edits:

### 1. `modules/system/claude.nix`

Already provided. Add it to the module list in `flake.nix`, next to the other
system modules:

```nix
        ./modules/system/security.nix
        ./modules/system/claude.nix      # <-- add this line
```

### 2. `modules/system/security.nix` — remove the old firejail claude wrapper

The new module owns claude entirely; there is no longer a system-wide `claude`
binary (it lives in the devShell). Leaving the old firejail wrapper in place
would collide on `/run/current-system/sw/bin/claude`. Delete three things
(line numbers as of the version reviewed):

- **The whole `claude-wrapper` let-binding** — the block beginning
  `# ── Claude Code ──` / `claude-wrapper = pkgs.writeShellScriptBin "claude" ''`
  through its closing `'';` (lines **42–75**).
- **The `claude-wrapper` entry in `environment.systemPackages`** (line **145**).
- **The stale comment** "Brave and Claude use shell wrappers..." — change it to
  refer to Brave only (lines **103–104**).

Everything else in `security.nix` stays: Brave's firejail wrapper, mpv/yt-dlp/
qbittorrent wrappedBinaries, AppArmor, polkit, sudo, PAM, GNOME Keyring.

> Note: the `claude-code` overlay in your `flake.nix` can stay — the devShell
> reuses it (see `claude-sandbox/flake.nix`). Removing the wrapper does not
> remove the overlay.

## One-time setup (run as nimbus)

```bash
# 1. Make every file in claude-sandbox/ world-readable. The kernel enforces
#    the inode's mode bits through the dir bind, so 0600 files (the default
#    if your umask is 077) deny claude read access on the sandbox side —
#    and pure-mode flake evaluation aborts when it can't copy the dir.
chmod -R a+rX ~/.config/nixos/claude-sandbox

# 2. Lock the devShell flake (generates claude-sandbox/flake.lock).
cd ~/.config/nixos/claude-sandbox
nix flake lock
chmod 644 flake.lock

# 3. Rebuild so the user, mounts, polkit rule, and the
#    /home/nimbus/claude-projects tmpfiles rule all exist. The rebuild
#    creates ~/claude-projects with the right owner/group/mode/ACL — no
#    manual mkdir/chmod/setfacl required.
sudo nixos-rebuild switch --flake ~/.config/nixos#l390

# 4. Re-login (or `exec su - nimbus`). The rebuild added you to the
#    claude-shared group, but existing shells keep their original supplementary
#    groups — without this, ls /home/claude/.claude returns Permission denied.

# 5. Seed claude's home baseline (Tier 1). Manual, by design.
sudo cp -rT ~/.config/nixos/claude-home /home/claude/.claude
sudo chown -R claude:claude /home/claude/.claude

# 6. Drop in claude's Forgejo access token. Per-machine secret — NEVER in
#    the baseline. Replace PASTE_TOKEN_HERE with the token from Forgejo.
sudo -u claude bash -c 'umask 077 && cat > /home/claude/.netrc' <<EOF
machine 192.168.1.3
login clawed
password PASTE_TOKEN_HERE
EOF
sudo -u claude setfacl -b /home/claude/.netrc   # strip inherited ACL
sudo -u claude chmod 600 /home/claude/.netrc
```

## Daily use

```bash
claude-run                         # one-shot: machinectl + nix develop + claude
```

Or step by step:

```bash
machinectl shell claude@                       # drop into claude's session (no password)
nix develop /home/claude/workspace/claude-sandbox   # enter the pinned toolchain
claude                                         # run the agent
```

`nix develop` reads the RO-mounted flake at `~claude/workspace/claude-sandbox`.
To get a one-off tool without leaving the shell: `nix shell nixpkgs#<tool>`.

### After editing the bind-mounted source files

The whole `claude-sandbox/` directory is exposed as a single read-only
*directory* bind mount, not as individual file binds. Atomic file rewrites
inside the directory (almost every editor, `nix flake lock`, etc.) propagate
without a mount-unit restart — no `fix-stale-mounts` dance required. A fresh
`nix develop` is enough to pick up the new contents.

## Promoting changes back

Two scripts packaged in the devShell handle the sandbox → host flow.
Claude runs them from inside the sandbox; each prints the exact host
command for you to copy-paste.

**Sandbox state → claude-home baseline** (`CLAUDE.md`, `settings.json`,
`memory/`, `skills/`):

```bash
# Inside the sandbox:
promote-claude-home
# → prints a `cp -rT ~/claude-projects/<bundle> ~/.config/nixos/claude-home/` line.
# Run that on the host, then review `git diff claude-home/` and commit.
```

**Sandbox-side nixos clone → live `~/.config/nixos/`** (any worktree change
claude made in `~/workspace/projects/my-conf/nixos/`):

```bash
# Inside the sandbox:
promote-nixos
# → prints `cp -rT` + `git add` (+ `git rm` for deletions) + status.
# Run that on the host, then `rebuild`.
```

**Per-machine secrets** (`~/.netrc` Forgejo token, anything similar) are
**never** promoted by either script — their allowlists explicitly exclude
them. Set them once per machine via the One-time setup steps above.

**A tool claude wanted permanently** — check its log, add to `packages.nix`,
commit:

```bash
cat /home/claude/workspace/tool-usage.log     # nimbus can read claude's home
# edit ~/.config/nixos/claude-sandbox/packages.nix, then:
cd ~/.config/nixos && git add -p && git commit
```

**Pushing an updated baseline back into claude's home** (does NOT happen
automatically — seeding is manual):

```bash
sudo cp ~/.config/nixos/claude-home/settings.json /home/claude/.claude/settings.json
sudo chown claude:claude /home/claude/.claude/settings.json
```

## Verification after first rebuild

Run these in a **fresh** shell (post-rebuild re-login), so `claude-shared`
group membership is active:

```bash
id | grep claude-shared                      # confirm the shell has the new group
sudo passwd -S claude                        # 'L' (locked)
getent group claude-shared                   # lists nimbus and claude
stat -c '%U:%G %a' /home/claude              # claude:claude-shared 750
machinectl shell claude@ /bin/sh -c 'echo $DISPLAY; id'   # DISPLAY empty; uid 9000
findmnt -t none | grep claude/workspace      # 1 dir bind (ro, claude-sandbox) + 1 dir bind (rw, projects)
# nimbus can read claude's home, but claude cannot read nimbus's:
ls /home/claude/.claude                      # works (group read via claude-shared)
machinectl shell claude@ /bin/sh -c 'cat /home/nimbus/.ssh/* 2>&1 | head -1'  # Permission denied
```

## What's deferred (by your decision)

- **claude git identity** — automatic commits of `~claude/.claude/` for
  rollback/durability. You'll wire this later. Until then, durability of
  claude's home state is "it's a file on disk" + your manual promote copies.
- **`nix shell` logging wrapper** — currently tool tracking is CLAUDE.md-only
  (claude is asked to append to `tool-usage.log`). The enforced wrapper is a
  clean later add: drop a `writeShellScriptBin "nix"` shim ahead of real nix on
  PATH in `devshell.nix`. Nothing else depends on it.
- **Config seeding** — deliberately dropped; `cp` your nixos config into
  claude's space by hand if/when you want claude to edit it.
