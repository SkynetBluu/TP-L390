# modules/system/caveman.nix
# Declarative sandbox for the Caveman Code agent — sibling to claude.nix.
#
# Same design as claude.nix (read that file's header for the full rationale).
# Three deliberate differences:
#
#   1. Separate user (`caveman`, uid 9001) and shared group (`caveman-shared`).
#      Caveman runs in autopilot — no permission prompts before edits, no shell
#      approval gate. A stricter blast radius is worth the duplicated module.
#      claude and caveman do NOT share a uid, do NOT see each other's homes,
#      and do NOT share project directories. The two sandboxes are isolated
#      from each other at the kernel level.
#
#   2. Entry via direnv. Caveman's `.envrc` (RO bind-mounted from the sandbox
#      flake) calls `use flake`, so `cd ~/workspace` auto-activates the pinned
#      toolchain. No explicit `nix develop` step in the daily flow.
#
#   3. No claude-code overlay. caveman-code is not in nixpkgs; the sandbox
#      flake npm-installs it into ~/.npm-global on first entry, pinned by
#      version. Replace with a proper derivation when one exists.
#
# Reuses (does not redeclare) from claude.nix:
#   - services.machined / polkit host-shell rule (the rule is scoped to nimbus
#     as subject, so it covers `machinectl shell caveman@` too).
#   - programs.direnv: not in claude.nix yet — added here system-wide so the
#     hook installs into bash's interactiveShellInit for both users. Direnv is
#     a no-op outside .envrc dirs, so this is safe for nimbus.
#
# One-time setup (run as nimbus, after first rebuild):
#
#   mkdir -p ~/caveman-projects
#   sudo chgrp caveman-shared ~/caveman-projects
#   chmod 2770 ~/caveman-projects
#   setfacl -d -m g:caveman-shared:rwX ~/caveman-projects
#
#   cd ~/.config/nixos/caveman-sandbox
#   nix flake lock
#
#   sudo nixos-rebuild switch --flake ~/.config/nixos#l390
#
#   # Seed the home baseline (Tier 1). Manual, by design.
#   sudo cp -rT ~/.config/nixos/caveman-home /home/caveman/.cave
#   sudo chown -R caveman:caveman /home/caveman/.cave
#
# Daily use:
#
#   machinectl shell caveman@
#   cd ~/workspace                       # direnv loads the pinned toolchain
#   direnv allow                          # once, on first entry or .envrc bump
#   caveman                               # first run installs the CLI

{ config, lib, pkgs, ... }:

let
  # ── Tunables ────────────────────────────────────────────────────────────
  cavemanUid = 9001;
  cavemanGid = 9001;

  cavemanHome = "/home/caveman";

  # The flake's directory is exposed read-only into caveman's workspace.
  flakeSrc = "/home/nimbus/.config/nixos/caveman-sandbox";

  # nimbus-owned, bind-mounted RW. Kept separate from ~/claude-projects.
  projectsSrc = "/home/nimbus/caveman-projects";
  projectsDst = "${cavemanHome}/workspace/projects";

  roBind = src: {
    device = src;
    fsType = "none";
    options = [ "bind" "ro" "nofail" ];
  };
in
{
  # ── User and groups ───────────────────────────────────────────────────────
  users.groups.caveman.gid = cavemanGid;

  # Bridge group: nimbus joins so it can read into caveman's home. Same
  # asymmetric pattern as claude-shared. claude is deliberately NOT a member.
  users.groups.caveman-shared.members = [ "nimbus" "caveman" ];

  users.users.caveman = {
    isNormalUser = true;
    description = "Caveman Code sandbox runtime";
    uid = cavemanUid;
    group = "caveman";
    extraGroups = [ "caveman-shared" ];
    home = cavemanHome;
    createHome = true;
    homeMode = "0750";
    shell = pkgs.bashInteractive;

    hashedPassword = "!";
    openssh.authorizedKeys.keys = lib.mkForce [ ];
  };

  systemd.tmpfiles.rules = [
    "z ${cavemanHome} 0750 caveman caveman-shared - -"
    "d ${cavemanHome}/workspace 0750 caveman caveman-shared - -"
    "d ${cavemanHome}/workspace/caveman-sandbox 0750 caveman caveman-shared - -"
    "d ${projectsDst} 0750 caveman caveman-shared - -"

    # Source-side projects dir (nimbus-side), re-asserted on every rebuild.
    "d ${projectsSrc} 2770 nimbus caveman-shared - -"
    "A+ ${projectsSrc} - - - - d:group:caveman-shared:rwX"

    # Default ACL: anything caveman creates stays group-readable by nimbus.
    "A+ ${cavemanHome} - - - - d:group:caveman-shared:r-X"
    "A+ ${cavemanHome} - - - - group:caveman-shared:r-X"
  ];

  # ── machinectl entry ──────────────────────────────────────────────────────
  # services.machined isn't enabled here — machined socket-activates on first
  # use, and claude.nix's polkit rule already grants nimbus host-shell access
  # for any target user (the action carries no target detail to gate on).

  # ── direnv ────────────────────────────────────────────────────────────────
  # System-wide. nix-direnv lets `.envrc` say `use flake` and reuse the
  # `nix develop` realisation, with proper caching across `cd` cycles.
  # Both caveman and nimbus get the bash hook; it's a no-op outside .envrc dirs.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ── Bind mounts ───────────────────────────────────────────────────────────
  # Whole caveman-sandbox/ dir RO, mirroring claude.nix's single-dir-bind
  # pattern (avoids stale-inode issues that bit per-file binds).
  fileSystems."${cavemanHome}/workspace/caveman-sandbox" = roBind flakeSrc;

  # Workspace-root .envrc, bind-mounted from the sandbox flake. This is what
  # direnv picks up when caveman cds into ~/workspace.
  fileSystems."${cavemanHome}/workspace/.envrc" =
    roBind "${flakeSrc}/.envrc";

  # Projects: nimbus-owned, RW.
  fileSystems."${projectsDst}" = {
    device = projectsSrc;
    fsType = "none";
    options = [ "bind" "nofail" ];
  };

  systemd.services."caveman-workspace-deps" = {
    description = "Ordering anchor: caveman bind mounts require /home";
    wantedBy = [ "local-fs.target" ];
    unitConfig.RequiresMountsFor = [ "/home" flakeSrc projectsSrc ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };
  };
}
