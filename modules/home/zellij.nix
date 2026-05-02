# modules/home/zellij.nix
# Zellij terminal session manager
# Custom Catppuccin Mocha theme using exact colours from theme.nix
# accent = blue (#89b4fa) to match the rest of the system

{ pkgs, ... }:

{
  home.packages = [ pkgs.zellij ];

  xdg.configFile."zellij/config.kdl".text = ''
    // ── Appearance ────────────────────────────────────────────────────────────
    theme "catppuccin-mocha-blue"
    pane_frames false
    simplified_ui false

    // ── Behaviour ─────────────────────────────────────────────────────────────
    default_shell "bash"
    copy_on_select true
    copy_command "wl-copy"
    scrollback_lines_to_keep 10000
    mouse_mode true

    // ── Theme ─────────────────────────────────────────────────────────────────
    // Catppuccin Mocha with blue accent — matches theme.nix exactly
    // ribbon_selected   = focused tab / active mode indicator
    // ribbon_unselected = other tabs / inactive items
    // text_selected     = selected text in lists/search
    // text_unselected   = normal text in lists/search
    themes {
      catppuccin-mocha-blue {
        ribbon_selected {
          base       "#1e1e2e"   // background — text on selected ribbon
          background "#89b4fa"   // accent blue — selected tab/mode bg
          emphasis_0 "#cba6f7"   // mauve — secondary accent
          emphasis_1 "#cdd6f4"   // foreground — bright text
          emphasis_2 "#a6e3a1"   // green
          emphasis_3 "#f9e2af"   // yellow
        }
        ribbon_unselected {
          base       "#cdd6f4"   // foreground — text on unselected ribbon
          background "#313244"   // surface — unselected tab bg
          emphasis_0 "#89b4fa"   // blue
          emphasis_1 "#bac2de"   // foreground dim
          emphasis_2 "#a6e3a1"   // green
          emphasis_3 "#f9e2af"   // yellow
        }
        text_selected {
          base       "#1e1e2e"   // background
          background "#89b4fa"   // blue highlight
          emphasis_0 "#cba6f7"   // mauve
          emphasis_1 "#cdd6f4"   // foreground
          emphasis_2 "#a6e3a1"   // green
          emphasis_3 "#f9e2af"   // yellow
        }
        text_unselected {
          base       "#cdd6f4"   // foreground
          background "#1e1e2e"   // background
          emphasis_0 "#89b4fa"   // blue
          emphasis_1 "#bac2de"   // foreground dim
          emphasis_2 "#a6e3a1"   // green
          emphasis_3 "#f9e2af"   // yellow
        }
      }
    }

    // ── Keybindings ───────────────────────────────────────────────────────────
    keybinds {
      normal {
        // Pane management
        bind "Alt n"         { NewPane; }
        bind "Alt Shift n"   { NewPane "down"; }
        bind "Alt h"         { MoveFocus "Left"; }
        bind "Alt l"         { MoveFocus "Right"; }
        bind "Alt k"         { MoveFocus "Up"; }
        bind "Alt j"         { MoveFocus "Down"; }
        bind "Alt x"         { CloseFocus; }

        // Floating pane
        bind "Alt f"         { ToggleFloatingPanes; }
        bind "Alt Shift f"   { TogglePaneEmbedOrFloating; }

        // Tab management
        bind "Alt t"         { NewTab; }
        bind "Alt w"         { CloseTab; }
        bind "Alt ,"         { GoToPreviousTab; }
        bind "Alt ."         { GoToNextTab; }
        bind "Alt 1"         { GoToTab 1; }
        bind "Alt 2"         { GoToTab 2; }
        bind "Alt 3"         { GoToTab 3; }
        bind "Alt 4"         { GoToTab 4; }
        bind "Alt 5"         { GoToTab 5; }

        // Session
        bind "Alt q"         { Detach; }

        // Resize
        bind "Alt ="         { Resize "Increase"; }
        bind "Alt -"         { Resize "Decrease"; }

        // Scroll
        bind "Alt u"         { HalfPageScrollUp; }
        bind "Alt d"         { HalfPageScrollDown; }

        // Locked mode — pass all keys to terminal
        bind "Ctrl g"        { SwitchToMode "Locked"; }
      }

      locked {
        bind "Ctrl g"        { SwitchToMode "Normal"; }
      }
    }
  '';
}
