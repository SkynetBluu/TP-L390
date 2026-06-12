---
name: udev `:=` is locked against any later override
description: To tighten upstream udev rules shipped via services.udev.packages on NixOS, drop the package from that list and ship your own rules — a later `:=` cannot override an earlier `:=`.
type: feedback
originSessionId: 1b363c29-48b0-48a8-9321-c748ab096f47
---
In udev rules, `KEY:="value"` is "final assignment, disallow any later changes." That lock blocks override by *any* later rule, including another `:=`. Plain `KEY="value"` is also blocked once a `:=` has fired.

On NixOS, `services.udev.extraRules` lands in `/etc/udev/rules.d/99-local.rules`, lexically after package-shipped rules in `49-*.rules`. So if an upstream package sets e.g. `MODE:="0666"`, no rule in `extraRules` can tighten it.

**Why:** Hit this tightening `pkgs.stlink`'s rules from world-writable (`MODE:="0666"`) to plugdev-gated. `GROUP="plugdev"` from extraRules took effect (upstream never set GROUP), but `MODE="0660"` was silently ignored. Result was 0660-wanted, 0666-actual until we changed approach.

**How to apply:** When you need to tighten upstream udev rules on NixOS, drop the package from `services.udev.packages` and ship the complete ruleset yourself in `extraRules`. This is independent of `environment.systemPackages` — `services.udev.packages` only controls whether the rule files get installed, not the binaries. Keep the package in `systemPackages` if you want the CLI tools (e.g. `st-flash`, `st-info`) on PATH.

Verification when tightening: `getfacl /dev/bus/usb/<bus>/<dev>` after `udevadm control --reload && udevadm trigger --action=change <path>` (or a replug). `udevadm info -a` does NOT show MODE/GROUP/TAG — those are rule-side directives, not device attributes.
