# modules/home/home.nix
# Home Manager configuration for nimbus — imports all home modules

{ config, pkgs, inputs, theme, ... }:

{
  # ── Home Manager basics ───────────────────────────────────────────────────

  home.username = "nimbus";
  home.homeDirectory = "/home/nimbus";
  home.stateVersion = "24.11"; # Do not change after first install

  programs.home-manager.enable = true;

  # ── Imports ───────────────────────────────────────────────────────────────
  imports = [
    ./neovim.nix
    ./mako.nix
    ./swayosd.nix
    ./hyprlock.nix
    ./gtk.nix
    ./desktop-entries.nix
    ./scripts.nix
    ./waybar.nix
    ./rofi.nix
    ./mpv.nix
  ];

  # ── Packages ──────────────────────────────────────────────────────────────

  home.packages = with pkgs; [
    btop
    tree
    ripgrep
    fd
    jq
    fzf
    unzip
    zip
    p7zip
    lazygit
  ];

  # ── Git ───────────────────────────────────────────────────────────────────

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "nimbus";
        email = "redactedusername@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
      color.ui = true;
    };
    signing.format = "openpgp"; # silence stateVersion warning
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "Catppuccin-mocha";
    };
  };

  programs.lazygit.enable = true;

  # ── Alacritty ─────────────────────────────────────────────────────────────

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 12; y = 12; };
        decorations = "none";
        opacity = 0.95;
        startup_mode = "Windowed";
      };
      scrolling.history = 10000;
      font = {
        normal = { family = theme.fonts.mono; style = "Regular"; };
        bold = { style = "Bold"; };
        italic = { style = "Italic"; };
        size = theme.fonts.monoSize + 1; # 13pt
      };
      colors = {
        primary = { background = theme.colors.background; foreground = theme.colors.foreground; };
        normal = {
          black = theme.colors.surface;
          red = theme.colors.red;
          green = theme.colors.green;
          yellow = theme.colors.yellow;
          blue = theme.colors.blue;
          magenta = theme.colors.magenta;
          cyan = theme.colors.cyan;
          white = theme.colors.foregroundDim;
        };
      };
      keyboard.bindings = [
        { key = "C"; mods = "Control|Shift"; action = "Copy"; }
        { key = "V"; mods = "Control|Shift"; action = "Paste"; }
      ];
    };
  };

  # ── Bash ──────────────────────────────────────────────────────────────────

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      ".." = "cd ..";
      "..." = "cd ../..";
      grep = "grep --color=auto";
      df = "df -h";
      du = "du -h";
      free = "free -h";

      # NixOS shortcuts
      rebuild = "nh os switch ~/.config/nixos";
      update = "nh os switch --update ~/.config/nixos";
      cleanup = "nh clean all";

      # Claude Code update helper
      update-claude-code = "echo 'Update overlays/claude-code-latest.nix with latest version and hash'";
    };

    bashrcExtra = ''
      eval "$(starship init bash)"
      eval "$(fzf --bash)"
    '';
  };

  # ── Starship prompt ───────────────────────────────────────────────────────

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
      directory = { truncation_length = 3; style = "bold blue"; };
      git_branch = { symbol = " "; style = "bold purple"; };
      nix_shell = { symbol = " "; style = "bold cyan"; format = "[$symbol$state]($style) "; };
      character = { success_symbol = "[❯](bold green)"; error_symbol = "[❯](bold red)"; };
    };
  };

  # ── Hyprland (home config) ────────────────────────────────────────────────

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;

    settings = {
      monitor = "eDP-1,1920x1080@60,0x0,1";

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(45475aaa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        active_opacity = 1.0;
        inactive_opacity = 0.92;
        blur = { enabled = true; size = 6; passes = 3; };
        shadow = { enabled = true; range = 8; render_power = 2; color = "rgba(1a1a2eee)"; };
      };

      animations = {
        enabled = true;
        bezier = [ "easeOut, 0.16, 1, 0.3, 1" ];
        animation = [
          "windows, 1, 4, easeOut, slide"
          "fade,    1, 4, easeOut"
          "workspaces, 1, 5, easeOut, slidevert"
        ];
      };

      input = {
        kb_layout = "gb";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = true;
          scroll_factor = 0.8;
        };
      };

      dwindle = { preserve_split = true; };

      misc = { force_default_wallpaper = 0; disable_hyprland_logo = true; };

      exec-once = [
        "hypridle"
        "mako"
        "awww-daemon"
        "awww img ~/.config/nixos/wallpapers/hiroshi-tsubono-medium.jpg"
        "/run/current-system/sw/libexec/polkit-kde-authentication-agent-1"
        "wl-paste --type text --watch cliphist store"
        "nm-applet --indicator"
        "blueman-applet"
        "bluelight-auto"
        "perf-mode-daemon"
        "sleep 2 && swayosd-server"
      ];

      "$mod" = "SUPER";

      bind = [
        "$mod, Return,      exec, alacritty"
        "$mod, B,           exec, brave"
        "$mod, E,           exec, alacritty -e yazi"
        "$mod, Space,       exec, rofi -show drun"
        "$mod, O,           exec, quick-notes"
        "$mod SHIFT, S,     exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mod, Q,           killactive"
        "$mod, F,           fullscreen"
        "$mod, V,           togglefloating"
        "$mod, L,           exec, loginctl lock-session"
        "$mod, N,           exec, bluelight-toggle"
        "$mod SHIFT, N,     exec, bluelight-off"
        "$mod, M,           exec, battery-mode"
        "$mod SHIFT, M,     exec, perf-mode"
        "$mod SHIFT, T,     exec, touchpad-toggle"
        "$mod, F1,          exec, sysinfo-panel"
        "$mod, F2,          exec, wifi-manage reconnect"
        "$mod SHIFT, F2,    exec, wifi-manage scan"
        "$mod CTRL, F2,     exec, wifi-manage toggle"
        "$mod, left,        movefocus, l"
        "$mod, right,       movefocus, r"
        "$mod, up,          movefocus, u"
        "$mod, down,        movefocus, d"
        "$mod, 1,           workspace, 1"
        "$mod, 2,           workspace, 2"
        "$mod, 3,           workspace, 3"
        "$mod, 4,           workspace, 4"
        "$mod, 5,           workspace, 5"
        "$mod SHIFT, 1,     movetoworkspace, 1"
        "$mod SHIFT, 2,     movetoworkspace, 2"
        "$mod SHIFT, 3,     movetoworkspace, 3"
        "$mod SHIFT, 4,     movetoworkspace, 4"
        "$mod SHIFT, 5,     movetoworkspace, 5"
        "$mod, mouse_down,  workspace, e+1"
        "$mod, mouse_up,    workspace, e-1"
        "$mod SHIFT, E,     exec, hyprctl dispatch exit"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume,  exec, swayosd-client --output-volume=+5"
        ",XF86AudioLowerVolume,  exec, swayosd-client --output-volume=-5"
        ",XF86MonBrightnessUp,   exec, swayosd-client --brightness=+10"
        ",XF86MonBrightnessDown, exec, swayosd-client --brightness=-10"
      ];

      bindl = [
        ",XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl prev"
      ];

      windowrule = [
        # Brave → workspace 2
        "workspace 2, match:class brave-browser"

        # quick-notes → float, sized, centered
        "float on, match:class quick-notes"
        "size 800 600, match:class quick-notes"
        "center on, match:class quick-notes"
      ];
    };
  };

  # ── XDG ───────────────────────────────────────────────────────────────────

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true; # silence stateVersion warning
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
    };
  };
}
