# modules/home/ghostty.nix
# Ghostty terminal — used for yazi (sixel image previews) and as alt terminal
# Catppuccin Mocha theme matching the rest of the system

{ pkgs, theme, ... }:

{
  home.packages = [ pkgs.ghostty ];

  xdg.configFile."ghostty/config".text = ''
    # ── Font ──────────────────────────────────────────────────────────────────
    font-family = JetBrainsMono Nerd Font
    font-size = 13

    # ── Colours (Catppuccin Mocha) ────────────────────────────────────────────
    background = ${builtins.substring 1 6 theme.colors.background}
    foreground = ${builtins.substring 1 6 theme.colors.foreground}

    # Normal colours
    palette = 0=${builtins.substring 1 6 theme.colors.surface}
    palette = 1=${builtins.substring 1 6 theme.colors.red}
    palette = 2=${builtins.substring 1 6 theme.colors.green}
    palette = 3=${builtins.substring 1 6 theme.colors.yellow}
    palette = 4=${builtins.substring 1 6 theme.colors.blue}
    palette = 5=${builtins.substring 1 6 theme.colors.magenta}
    palette = 6=${builtins.substring 1 6 theme.colors.cyan}
    palette = 7=${builtins.substring 1 6 theme.colors.foregroundDim}

    # Bright colours (same palette, slightly brighter variants)
    palette = 8=${builtins.substring 1 6 theme.colors.border}
    palette = 9=${builtins.substring 1 6 theme.colors.red}
    palette = 10=${builtins.substring 1 6 theme.colors.green}
    palette = 11=${builtins.substring 1 6 theme.colors.yellow}
    palette = 12=${builtins.substring 1 6 theme.colors.accent}
    palette = 13=${builtins.substring 1 6 theme.colors.accentSecondary}
    palette = 14=${builtins.substring 1 6 theme.colors.cyan}
    palette = 15=${builtins.substring 1 6 theme.colors.foreground}

    # ── Window ────────────────────────────────────────────────────────────────
    background-opacity = 0.95
    window-padding-x = 12
    window-padding-y = 12
    window-decoration = false

    # ── Cursor ────────────────────────────────────────────────────────────────
    cursor-style = block
    cursor-style-blink = false

    # ── Scrollback ────────────────────────────────────────────────────────────
    scrollback-limit = 10000

    # ── Clipboard ─────────────────────────────────────────────────────────────
    clipboard-read = allow
    clipboard-write = allow

    # ── Graphics ──────────────────────────────────────────────────────────────
    # Sixel support for inline image previews in yazi
    image-storage-limit = 320000000

    # ── Shell integration ─────────────────────────────────────────────────────
    shell-integration = bash
    shell-integration-features = cursor,sudo,title

    # ── Keybinds ──────────────────────────────────────────────────────────────
    keybind = ctrl+shift+c=copy_to_clipboard
    keybind = ctrl+shift+v=paste_from_clipboard
    keybind = ctrl+shift+n=new_window
    keybind = ctrl+shift+t=new_tab
    keybind = ctrl+shift+w=close_surface
    keybind = ctrl+page_up=previous_tab
    keybind = ctrl+page_down=next_tab
    keybind = ctrl+shift+equal=increase_font_size:1
    keybind = ctrl+shift+minus=decrease_font_size:1
    keybind = ctrl+shift+zero=reset_font_size
  '';
}
