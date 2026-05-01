# TP-L390 — NixOS Configuration

> Declarative NixOS flake configuration for the **ThinkPad L390** (Intel i5-8365U / UHD 620)  
> Hyprland · LUKS · Btrfs · Catppuccin Mocha · Home Manager · Firejail

![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?style=flat&logo=nixos&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-latest-58E1FF?style=flat)
![License](https://img.shields.io/badge/license-MIT-green?style=flat)

---

## Hardware

| Component | Spec |
|-----------|------|
| CPU | Intel Core i5-8365U (Whiskey Lake, 4c/8t) |
| GPU | Intel UHD 620 |
| RAM | 16GB |
| Storage | 465GB SATA SSD |
| Wi-Fi | Intel Cannon Point-LP CNVi |
| Display | 13.3" 1920×1080 IPS |

---

## Features

- **Full disk encryption** — LUKS2 on root and swap partitions
- **Btrfs** with subvolumes (`@`, `@home`, `@nix`, `@snapshots`, `@log`) and zstd compression
- **Hibernation** — swap encrypted with LUKS, resume device configured
- **Hyprland** — Wayland compositor with UWSM, animations, gestures
- **Catppuccin Mocha** — unified theme across all apps (Waybar, Rofi, Neovim, Alacritty, Hyprlock)
- **Firejail sandboxing** — Brave, Brave HW profile, and Claude Code run in isolated sandboxes
- **Home Manager** — fully declarative user environment
- **TLP** — advanced laptop power management with ThinkPad charge thresholds
- **PipeWire** — modern audio stack with SwayOSD OSD
- **yt-dlp + mpv** — YouTube playback and download from the terminal
- **Blue light filter** — hyprsunset with 8 levels, auto-enabled at 2000K on login
- **Battery mode cycling** — conservation / balanced / full charge thresholds
- **Performance mode daemon** — systemd user service, auto battery saver on unplug
- **sops-nix** — encrypted secrets management (configured post-install)

---

## Structure

```
.
├── flake.nix                    # Inputs, overlays, system definition
├── flake.lock                   # Pinned input versions
├── hosts/
│   └── l390/
│       ├── configuration.nix    # Main system config
│       ├── disko-config.nix     # Declarative disk partitioning
│       └── hardware-configuration.nix  # Auto-generated hardware config
├── modules/
│   ├── home/                    # Home Manager modules
│   │   ├── home.nix             # Main HM entry point + Hyprland config
│   │   ├── theme.nix            # Catppuccin Mocha — single source of truth
│   │   ├── waybar.nix           # Status bar
│   │   ├── rofi.nix             # App launcher
│   │   ├── neovim.nix           # Editor with LSP, treesitter, AI
│   │   ├── hyprlock.nix         # Lock screen + idle daemon (hypridle)
│   │   ├── mako.nix             # Notifications
│   │   ├── swayosd.nix          # Volume/brightness OSD
│   │   ├── gtk.nix              # GTK theming + cursor
│   │   ├── mpv.nix              # mpv + yt-dlp + YouTube scripts
│   │   ├── desktop-entries.nix  # XDG desktop entries + launcher scripts
│   │   └── scripts.nix          # Helper scripts (battery, bluelight, wifi, etc.)
│   └── system/                  # NixOS modules
│       ├── boot.nix             # Bootloader, LUKS, kernel
│       ├── hyprland.nix         # Hyprland system config, Mesa pin, suspend fix
│       ├── networking.nix       # NetworkManager, DNS
│       ├── security.nix         # Firejail, AppArmor, PAM, GNOME Keyring
│       ├── sound.nix            # PipeWire
│       ├── fonts.nix            # System-wide fonts
│       ├── locale.nix           # Locale, keyboard
│       └── users.nix            # User accounts
└── overlays/
    └── claude-code-latest.nix   # Claude Code prebuilt binary from npm
└── wallpapers/
    └── hiroshi-tsubono-medium.jpg  # Default wallpaper
```

---

## Wallpaper

Wallpaper is managed by `awww` and set on login via `exec-once`. To change it:

```bash
# Copy your image to the wallpapers directory
cp ~/Pictures/your-wallpaper.jpg ~/.config/nixos/wallpapers/

# Set it immediately
awww img ~/.config/nixos/wallpapers/your-wallpaper.jpg
```

Then update `exec-once` in `modules/home/home.nix` to point to the new file and `rebuild`.

---

## Theme

All colours and fonts are defined in `modules/home/theme.nix` and passed to every module via `specialArgs`. To change the theme globally, edit that file and run `rebuild`.

**Current theme:** Catppuccin Mocha with blue accent (`#89b4fa`)

| Color | Hex |
|-------|-----|
| Background | `#1e1e2e` |
| Surface | `#313244` |
| Foreground | `#cdd6f4` |
| Accent (Blue) | `#89b4fa` |
| Red | `#f38ba8` |
| Green | `#a6e3a1` |

---

## Key Bindings

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (Alacritty) |
| `Super + B` | Browser (Brave) |
| `Super + E` | File manager (Yazi) |
| `Super + Space` | App launcher (Rofi) |
| `Super + O` | Quick notes (Neovim) |
| `Super + Q` | Kill window |
| `Super + F` | Fullscreen |
| `Super + V` | Float/tile toggle |
| `Super + L` | Lock screen |
| `Super + 1-5` | Switch workspace |
| `Super + Shift + 1-5` | Move window to workspace |
| `Super + N` | Blue light filter cycle |
| `Super + Shift + N` | Blue light filter off |
| `Super + M` | Battery mode cycle |
| `Super + Shift + M` | Performance mode cycle |
| `Super + Shift + T` | Toggle touchpad |
| `Super + F1` | System info panel |
| `Super + F2` | WiFi reconnect |
| `Super + Shift + F2` | WiFi scan (wofi picker) |
| `Super + Ctrl + F2` | WiFi toggle on/off |
| `Super + Shift + S` | Screenshot region → clipboard |
| `Super + Shift + E` | Exit Hyprland |

---

## Installation

### Prerequisites

- NixOS live ISO booted (graphical or minimal)
- Internet connection (`nmtui`)
- This repo cloned

### Steps

**1. Clone the repo**
```bash
git clone https://github.com/SkynetBluu/TP-L390.git
cd TP-L390
```

**2. Enable flakes**
```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

**3. Partition and format with disko**
```bash
sudo nix run github:nix-community/disko -- --mode disko hosts/l390/disko-config.nix
```

**4. Generate hardware config**
```bash
sudo nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/l390/
```

**5. Install**
```bash
sudo nixos-install --flake .#l390 --no-root-passwd
```

**6. Set user password**
```bash
sudo nixos-enter --root /mnt -c 'passwd nimbus'
```

**7. Reboot**
```bash
reboot
```

---

## Post-Install

**Place config in the right location:**
```bash
git clone https://github.com/SkynetBluu/TP-L390.git ~/.config/nixos
```

**Update the cryptswap UUID** in `modules/system/boot.nix`:
```bash
blkid /dev/sda3  # get UUID of the swap partition
# update: cryptswap.device = lib.mkForce "/dev/disk/by-uuid/YOUR-UUID";
```

**Set up sops-nix secrets** (after first boot):
```bash
sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key
# add public key to .sops.yaml
# uncomment sops block in configuration.nix
```

---

## Daily Commands

```bash
rebuild   # nh os switch ~/.config/nixos
update    # nh os switch --update ~/.config/nixos
cleanup   # nh clean all
```

---

## Updating Claude Code

The Claude Code overlay fetches a pinned binary from npm. To update:

```bash
# 1. Check latest version
npm view @anthropic-ai/claude-code version

# 2. Get the hash
nix-prefetch-url "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-VERSION.tgz"

# 3. Convert to SRI format
nix hash convert --hash-algo sha256 --to sri HASH

# 4. Update version and sha256 in overlays/claude-code-latest.nix, then:
rebuild
```

---

## YouTube / Media

mpv is configured with yt-dlp for seamless YouTube playback.

| Command | What it does |
|---------|-------------|
| `yewtube` | Full TUI YouTube browser |
| `yts <query>` | Search YouTube with fzf, play in mpv |
| `ytp <url>` | Play URL directly in mpv |
| `ytd <url> [video\|audio\|best]` | Download video |
| `ytmp3 <url>` | Download as MP3 to ~/Music |
| `ytq add <url>` | Add to watch-later queue |
| `ytq play` | Play the queue |
| `ytc <url> <start> <end>` | Play a specific clip |
| `ytmusic <url>` | Audio-only playback |
| `ytbg <url>` | Play audio in background |

**mpv key bindings:**

| Key | Action |
|-----|--------|
| `[` / `]` | Speed -0.25 / +0.25 |
| `BS` | Reset speed to 1.0 |
| `l` | A-B loop |
| `s` | Screenshot |
| `v` | Toggle subtitles |
| `a` | Cycle audio tracks |
| `Shift+Left/Right` | Seek ±1 second |

---

## Disk Layout

```
/dev/sda1   1MB       BIOS boot gap
/dev/sda2   512MB     EFI system partition (/boot)
/dev/sda3   16GB      Swap (LUKS encrypted)
/dev/sda4   ~449GB    Root (LUKS2 → Btrfs)
```

**Btrfs subvolumes:**
```
@           /
@home       /home
@nix        /nix
@snapshots  /.snapshots
@log        /var/log
```

---

## Security

- Full disk encryption with LUKS2 on root and swap
- Brave browser sandboxed with Firejail (strict profile, `~/Downloads` only)
- `brave-hw` — separate Brave instance with its own profile and broader whitelist (for hardware/dev sites)
- Claude Code sandboxed with Firejail (`~/projects`, `~/Documents`, `~/.config/claude`, `~/.local/share/claude`)
- AppArmor enabled
- sudo requires password (wheel group)
- Passwordless sudo only for `tlp setcharge` (battery threshold management)
- GNOME Keyring for VS Code / Electron credential storage
- Root login disabled

---

## Credits

- [NixOS](https://nixos.org/) — the operating system
- [Hyprland](https://hyprland.org/) — Wayland compositor
- [Catppuccin](https://catppuccin.com/) — colour scheme
- [nixos-hardware](https://github.com/NixOS/nixos-hardware) — ThinkPad X390 profile (closest match for L390)
- [disko](https://github.com/nix-community/disko) — declarative disk partitioning
- [home-manager](https://github.com/nix-community/home-manager) — user environment
- [sops-nix](https://github.com/Mic92/sops-nix) — encrypted secrets management
