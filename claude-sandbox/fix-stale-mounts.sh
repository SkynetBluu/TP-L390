#!/usr/bin/env bash
# Refresh the claude-workspace bind mounts. Handles two failure modes:
#
#   1. Source materialized as a directory (when it didn't exist at first
#      mount, the kernel autocreated both ends as dirs). Bind-mount
#      file->directory fails forever after; we stop, rmdir, touch, start.
#
#   2. Stale inode (the source was atomically rewritten via tmp+rename,
#      so the mount still references the original inode with old content).
#      Restart the mount unit to capture the current inode.
#
# Idempotent — safe to run any time as nimbus.

set -euo pipefail

workspace=/home/claude/workspace
files=(flake.nix flake.lock devshell.nix packages.nix claude-code-latest.nix)

for f in "${files[@]}"; do
  target="$workspace/$f"
  # systemd escapes `-` inside path components as \x2d, so derive the unit
  # name from the path rather than building it by string concat.
  unit="$(systemd-escape --suffix=mount --path "$target")"

  if sudo test -d "$target"; then
    echo ">> repairing $target (was a directory)"
    sudo systemctl stop "$unit" || true
    sudo rmdir "$target"
    sudo -u claude touch "$target"
    sudo systemctl start "$unit"
  else
    echo ">> refreshing $unit"
    sudo systemctl restart "$unit"
  fi

  sudo systemctl is-active --quiet "$unit" \
    && echo "   active" \
    || { echo "   FAILED; see: systemctl status $unit" >&2; exit 1; }
done
