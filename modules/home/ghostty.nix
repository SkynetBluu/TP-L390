# modules/home/ghostty.nix
# Ghostty terminal — used for yazi (sixel image previews) and as alt terminal
# Catppuccin Mocha theme matching the rest of the system

{ pkgs, theme, ... }:

let
  hex = c: builtins.substring 1 6 c;
in
{
  programs.ghostty = {
    enable = true;

    settings = {
      # ── Font ──────────────────────────────────────────────────────────────
      font-family = theme.fonts.mono;
      font-size = 13;

      # ── Colours (Catppuccin Mocha) ────────────────────────────────────────
      background = hex theme.colors.background;
      foreground = hex theme.colors.foreground;

      # Normal colours (0–7) and bright colours (8–15)
      palette = [
        "0=${hex theme.colors.surface}"
        "1=${hex theme.colors.red}"
        "2=${hex theme.colors.green}"
        "3=${hex theme.colors.yellow}"
        "4=${hex theme.colors.blue}"
        "5=${hex theme.colors.magenta}"
        "6=${hex theme.colors.cyan}"
        "7=${hex theme.colors.foregroundDim}"
        "8=${hex theme.colors.border}"
        "9=${hex theme.colors.red}"
        "10=${hex theme.colors.green}"
        "11=${hex theme.colors.yellow}"
        "12=${hex theme.colors.accent}"
        "13=${hex theme.colors.accentSecondary}"
        "14=${hex theme.colors.cyan}"
        "15=${hex theme.colors.foreground}"
      ];

      # ── Window ────────────────────────────────────────────────────────────
      background-opacity = 0.95;
      window-padding-x = 12;
      window-padding-y = 12;
      window-decoration = false;

      # ── Cursor ────────────────────────────────────────────────────────────
      cursor-style = "block";
      cursor-style-blink = false;

      # ── Scrollback ────────────────────────────────────────────────────────
      scrollback-limit = 10000;

      # ── Clipboard ─────────────────────────────────────────────────────────
      clipboard-read = "allow";
      clipboard-write = "allow";
      copy-on-select = "clipboard";

      # ── Graphics ──────────────────────────────────────────────────────────
      # Sixel support for inline image previews in yazi
      image-storage-limit = 320000000;

      # ── Shell integration ─────────────────────────────────────────────────
      shell-integration = "bash";
      shell-integration-features = "cursor,sudo,title";

      # ── Keybinds ──────────────────────────────────────────────────────────
      keybind = [
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+shift+n=new_window"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+w=close_surface"
        "ctrl+page_up=previous_tab"
        "ctrl+page_down=next_tab"
        "ctrl+shift+equal=increase_font_size:1"
        "ctrl+shift+minus=decrease_font_size:1"
        "ctrl+shift+zero=reset_font_size"
      ];
    };
  };
}
