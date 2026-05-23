# Claude sandbox — declarative, reproducible, isolated

A dedicated `claude` user (uid 9000) gives kernel-enforced separation from
`nimbus`. Entry is via `machinectl shell claude@` (clean logind session — no
inherited `$DISPLAY`, Wayland socket, or dbus bus). The toolchain is a pinned
Nix devShell, bind-mounted read-only into claude's workspace. Projects are a
nimbus-owned directory bind-mounted read-write. Home state is managed by hand.

```
/home/nimbus/.config/nixos/
├── claude-sandbox/              # nimbus-owned; bind-mounted RO into claude
│   ├── flake.nix
│   ├── flake.lock               # generated on first `nix flake lock` (see setup)
│   ├── devshell.nix             # env + shellHook (load-bearing)
│   └── packages.nix             # the locked toolchain — single source of truth
├── claude-home/                 # Tier 1 baseline; copied by hand into ~claude/.claude
│   ├── CLAUDE.md
│   └── settings.json
└── modules/system/claude.nix    # the user, group, perms, machined, polkit, mounts

/home/nimbus/claude-projects/    # nimbus owns; bind-mounted RW -> claude workspace
/home/claude/                    # claude:claude-shared 0750 (nimbus can read)
└── workspace/
    ├── flake.nix  flake.lock  devshell.nix  packages.nix   # RO bind mounts
    ├── projects/                                            # RW bind mount
    └── tool-usage.log                                       # claude's wishlist
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

## One-time setup (run as nimbus, after first rebuild)

```bash
# 1. Create the projects source dir, group-owned so claude can write into it
#    through the bind mount, and set a default ACL so new files stay shared.
mkdir -p ~/claude-projects
sudo chgrp claude-shared ~/claude-projects
chmod 2770 ~/claude-projects                       # setgid: new files inherit group
setfacl -d -m g:claude-shared:rwX ~/claude-projects

# 2. Lock the devShell flake (generates claude-sandbox/flake.lock).
cd ~/.config/nixos/claude-sandbox
nix flake lock

# 3. Rebuild so the user, mounts, and polkit rule exist.
sudo nixos-rebuild switch --flake ~/.config/nixos#l390

# 4. Seed claude's home baseline (Tier 1). Manual, by design.
sudo cp -rT ~/.config/nixos/claude-home /home/claude/.claude
sudo chown -R claude:claude /home/claude/.claude
```

## Daily use

```bash
machinectl shell claude@           # drop into claude's session (no password)
cd ~/workspace                     # = /home/claude/workspace
nix develop                        # enter the pinned toolchain
claude                             # run the agent
```

`nix develop` reads the RO-mounted flake. To get a one-off tool without
leaving the shell: `nix shell nixpkgs#<tool>`.

## Promoting changes back (manual)

**A tool claude wanted permanently** — check its log, add to `packages.nix`,
commit:

```bash
cat /home/claude/workspace/tool-usage.log     # nimbus can read claude's home
# edit ~/.config/nixos/claude-sandbox/packages.nix, then:
cd ~/.config/nixos && git add -p && git commit
```

**A settings/skill change worth keeping** — copy it out, diff, commit:

```bash
cp /home/claude/.claude/settings.json ~/.config/nixos/claude-home/settings.json
cd ~/.config/nixos && git diff claude-home/   # review before committing
```

**Pushing an updated baseline back into claude's home** (does NOT happen
automatically — seeding is manual):

```bash
sudo cp ~/.config/nixos/claude-home/settings.json /home/claude/.claude/settings.json
sudo chown claude:claude /home/claude/.claude/settings.json
```

## Verification after first rebuild

```bash
id claude                                    # uid=9000, groups: claude, claude-shared
sudo passwd -S claude                        # 'L' (locked)
getent group claude-shared                   # lists nimbus and claude
stat -c '%U:%G %a' /home/claude              # claude:claude-shared 750
machinectl shell claude@ /bin/sh -c 'echo $DISPLAY; id'   # DISPLAY empty; uid 9000
findmnt /home/claude/workspace/flake.nix     # bind mount, ro
findmnt /home/claude/workspace/projects      # bind mount, rw
# nimbus can read claude's home, but claude cannot read nimbus's:
ls /home/claude/.claude                      # works (group read)
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
