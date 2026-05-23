# modules/system/claude.nix
# Declarative, reproducible, security-isolated environment for Claude Code.
#
# Design (see claude-sandbox/README.md for the full rationale):
#
#   Security boundary  — a dedicated unprivileged `claude` user (uid 9000).
#                        Kernel-enforced separation from `nimbus`: ~nimbus is
#                        mode 0700, so claude (uid 9000) literally cannot read
#                        nimbus's SSH keys, GnuPG, etc. No firejail, no sudo
#                        wrapper — the uid wall is the boundary.
#
#   Asymmetric access  — /home/claude is 0750 owned claude:claude-shared, and
#                        nimbus is a member of claude-shared. So nimbus can READ
#                        everything under claude's home (inspect skills, state,
#                        promote files back by hand), while claude still cannot
#                        reach into ~nimbus. One-directional, by design.
#
#   Entry point        — `machinectl shell claude@`. Gives claude its own logind
#                        session + scope + XDG_RUNTIME_DIR, and crucially does
#                        NOT inherit nimbus's $DISPLAY / Wayland socket / dbus
#                        session bus. The agent is a headless tenant with no line
#                        of sight to nimbus's graphical session. A polkit rule
#                        lets nimbus open that session without a password.
#
#   Reproducibility    — the toolchain comes from claude-sandbox/ (a flake
#                        devShell), exposed read-only into claude's workspace via
#                        bind mounts. claude runs `nix develop` there. The flake
#                        is nimbus-owned; claude cannot rewrite its own toolchain.
#
#   Projects           — a nimbus-owned directory bind-mounted (read-write) into
#                        claude's workspace. The code is really nimbus's; claude
#                        edits it through the mount; nimbus is the git committer.
#
#   Home state         — fully manual. nimbus copies the baseline in
#                        (claude-home/ -> ~claude/.claude/) and promotes changes
#                        back out by hand. No activation seeding, no flags.
#
# This module does NOT define a system-wide `claude` binary. The old firejail
# `claude-wrapper` in modules/system/security.nix must be removed (see README).

{ config, lib, pkgs, ... }:

let
  # ── Tunables ────────────────────────────────────────────────────────────
  claudeUid = 9000;
  claudeGid = 9000;

  claudeHome = "/home/claude";

  # The flake lives in nimbus's repo. These files are exposed read-only into
  # claude's workspace so `nix develop` works but claude can't edit them.
  flakeSrc    = "/home/nimbus/.config/nixos/claude-sandbox";
  overlaysSrc = "/home/nimbus/.config/nixos/overlays";

  # The project area. nimbus owns this directory; it is bind-mounted into
  # claude's workspace read-write so claude can edit code and nimbus can commit.
  projectsSrc = "/home/nimbus/claude-projects";
  projectsDst = "${claudeHome}/workspace/projects";

  # Helper: a read-only bind mount of a single file from the repo into claude's
  # workspace. The attribute name (the mountpoint) is the destination; this just
  # supplies the source + options. `nofail` so a missing source can't wedge boot.
  roBind = src: {
    device = src;
    fsType = "none";
    options = [ "bind" "ro" "nofail" ];
  };
in
{
  # ── User and groups ───────────────────────────────────────────────────────
  users.groups.claude.gid = claudeGid;

  # The bridge group: nimbus joins it so it can read into claude's home.
  # claude is the owning user of its home; the group is the read side for nimbus.
  users.groups.claude-shared.members = [ "nimbus" "claude" ];

  users.users.claude = {
    isNormalUser = true;
    description  = "Claude Code sandbox runtime";
    uid          = claudeUid;
    group        = "claude";
    extraGroups  = [ "claude-shared" ];
    home         = claudeHome;
    createHome   = true;
    # 0750 so the claude-shared group (nimbus) can read; 'other' gets nothing.
    homeMode     = "0750";
    shell        = pkgs.bashInteractive;

    # Locked: never logged into via password. Reached only via
    # `machinectl shell claude@`. Also no SSH keys (see openssh below).
    hashedPassword = "!";

    # Defensive: ensure no other module slips an authorized key onto claude.
    openssh.authorizedKeys.keys = lib.mkForce [ ];
  };

  # Make claude's home group-owned by claude-shared so the 0750 group bit
  # actually grants nimbus read access. (createHome sets owner; we fix the
  # group + a default ACL so newly-created files stay group-readable.)
  systemd.tmpfiles.rules = [
    # Own the home claude:claude-shared, 0750.
    "z ${claudeHome} 0750 claude claude-shared - -"

    # Workspace skeleton (so the bind-mount targets exist before mounting).
    "d ${claudeHome}/workspace 0750 claude claude-shared - -"
    "d ${projectsDst} 0750 claude claude-shared - -"

    # Pre-create the bind-mount target files. Without these, if the source
    # is ever missing at first mount, systemd-mount auto-materializes the
    # target as a *directory* — and then bind-mount file→dir fails forever
    # after. `f` creates the file if absent, leaves it alone if present.
    "f ${claudeHome}/workspace/flake.nix              0644 claude claude-shared - -"
    "f ${claudeHome}/workspace/flake.lock             0644 claude claude-shared - -"
    "f ${claudeHome}/workspace/devshell.nix           0644 claude claude-shared - -"
    "f ${claudeHome}/workspace/packages.nix           0644 claude claude-shared - -"
    "f ${claudeHome}/workspace/claude-code-latest.nix 0644 claude claude-shared - -"

    # Default ACL: anything claude creates under its home stays readable by
    # the claude-shared group (so nimbus can always inspect it), without
    # making it group-writable. Capital X = dirs get +x, files don't.
    "A+ ${claudeHome} - - - - d:group:claude-shared:r-X"
    "A+ ${claudeHome} - - - - group:claude-shared:r-X"
  ];

  # ── machinectl entry ──────────────────────────────────────────────────────
  # systemd-machined is part of systemd itself and socket-activates on first
  # use of `machinectl shell claude@`, so nothing extra to install or enable.

  # Polkit: allow nimbus to open a host-shell session (machinectl shell ...@)
  # without a password. NOTE: the host-shell action carries no detail about
  # the *target* user, so this cannot be narrowed to "only become claude" — it
  # is scoped to the subject (nimbus) instead. This grants nimbus nothing it
  # lacks already (nimbus is in wheel and can sudo), it only removes the prompt.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.machine1.host-shell" &&
          subject.user == "nimbus") {
        return polkit.Result.YES;
      }
    });
  '';

  # ── Bind mounts: flake (read-only) + projects (read-write) ─────────────────
  #
  # The flake's files are exposed read-only so `nix develop` resolves them but
  # claude cannot modify its own toolchain definition. claude-code-latest.nix
  # is bind-mounted alongside flake.nix (not as ../overlays/...) so that pure-
  # mode evaluation, which copies the workspace dir to /nix/store/.../source,
  # still finds it via a local-relative path inside the flake.
  fileSystems."${claudeHome}/workspace/flake.nix"               = roBind "${flakeSrc}/flake.nix";
  fileSystems."${claudeHome}/workspace/flake.lock"              = roBind "${flakeSrc}/flake.lock";
  fileSystems."${claudeHome}/workspace/devshell.nix"            = roBind "${flakeSrc}/devshell.nix";
  fileSystems."${claudeHome}/workspace/packages.nix"            = roBind "${flakeSrc}/packages.nix";
  fileSystems."${claudeHome}/workspace/claude-code-latest.nix"  = roBind "${overlaysSrc}/claude-code-latest.nix";

  # Projects: nimbus-owned, bind-mounted read-write. The code is nimbus's;
  # claude edits through the mount; nimbus commits. Group-writable on the
  # source side (set up once by nimbus, see README) lets claude save files.
  fileSystems."${projectsDst}" = {
    device = projectsSrc;
    fsType = "none";
    options = [ "bind" "nofail" ];
  };

  # Ensure the bind mounts wait for /home (the encrypted btrfs @home subvol)
  # to be present, so activation/boot doesn't race the LUKS unlock.
  systemd.services."claude-workspace-deps" = {
    description = "Ordering anchor: claude bind mounts require /home";
    wantedBy = [ "local-fs.target" ];
    unitConfig.RequiresMountsFor = [ "/home" flakeSrc projectsSrc ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };
  };
}
