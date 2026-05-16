# modules/home/hyprlock.nix
# Hypridle + Hyprlock — idle daemon and lock screen
#
# 1920x1080 layout:
#
#   Centre (valign=center):
#     Clock    position 0, 200
#     Date     position 0, 120
#     Input    position 0,  20
#
#   Side panels (valign=top):
#     Y = distance down from top edge. Anchor = top of widget.
#     Both panels start at Y=-80. Body sits 30px below the heading.
#
#   Bottom bar (valign=bottom, Y=20)

{ theme, ... }:

let
  # Hyprlock accepts colours as rgba(RRGGBBAA) hex tokens — no parser needed.
  rgba = hex: alpha: "rgba(${builtins.substring 1 6 hex}${alpha})";

  fg     = rgba theme.colors.foreground    "ff";
  bg     = rgba theme.colors.background    "ff";
  dim    = rgba theme.colors.comment       "ff";
  accent = rgba theme.colors.accent        "ff";
  green  = rgba theme.colors.green         "ff";
  red    = rgba theme.colors.red           "ff";
  border = rgba theme.colors.border        "ff";

  # Build a (heading, body) pair as two label attrsets.
  mkSection = { heading, rows, x, headingY, halign }:
    let bodyY = headingY - 30; in
    [
      {
        monitor = "";
        text = heading;
        color = accent;
        font_size = 13;
        font_family = theme.fonts.mono;
        position = "${toString x}, ${toString headingY}";
        inherit halign;
        valign = "top";
      }
      {
        monitor = "";
        text = builtins.concatStringsSep "<br/>" rows;
        color = dim;
        font_size = 12;
        font_family = theme.fonts.mono;
        position = "${toString x}, ${toString bodyY}";
        inherit halign;
        valign = "top";
      }
    ];

  keybindRows = [
    "SUPER + Return           Terminal             Ghostty"
    "SUPER + Z                Session Manager      Zellij"
    "SUPER + B                Web Browser          Brave"
    "SUPER + E                File Explorer        Yazi"
    "SUPER + Space            Launcher             Rofi"
    "SUPER + O                Notes                Helix"
    "SUPER + K                KiCad"
    "SUPER + Shift + S        Screenshot"
    "SUPER + N                Blue light"
    "SUPER + M                Battery"
    "SUPER + Q                Kill"
    ""
    "SUPER + H                Horizontal split"
    "SUPER + V                Vertical split"
    "SUPER + R                Toggle H/V split"
    ""
    "SUPER + Arrow            Move focus"
    "SUPER + Shift + Arrow    Move window"
    "SUPER + Ctrl + Arrow     Resize"
    ""
    "SUPER + F                Fullscreen"
    "SUPER + G                Float/tile"
    ""
    "SUPER + 1-5              Workspace"
    "SUPER + Shift + 1-5      Move to Workspace"
    ""
    "SUPER + L                Lock"
    "SUPER + Shift + E        Exit"
  ];

  asciiRows = [
    "32  0x20  SPC"
    "48  0x30  0"
    "65  0x41  A"
    "97  0x61  a"
    "10  0x0A  LF"
    "13  0x0D  CR"
    "27  0x1B  ESC"
    " 9  0x09  TAB"
  ];
in
{
  # ── Hypridle ──────────────────────────────────────────────────────────────
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "sleep 2 && hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 1500;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 1800;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 2700;
          on-timeout = "sh -c '[ \"$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)\" = \"Discharging\" ] && systemctl suspend'";
        }
      ];
    };
  };

  # ── Hyprlock ──────────────────────────────────────────────────────────────
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 0;
        no_fade_in = true;
        no_fade_out = true;
      };

      background = [{
        monitor = "";
        path = "$WALLPAPER";
        blur_passes = 2;
        blur_size = 0.001;
        brightness = 0.8;
      }];

      label =
        [
          # Clock
          {
            monitor = "";
            text = "$TIME";
            color = fg;
            font_size = 96;
            font_family = theme.fonts.mono;
            position = "0, 200";
            halign = "center";
            valign = "center";
          }
          # Date
          {
            monitor = "";
            text = "cmd[update:60000] date '+%A %d %B %Y'";
            color = dim;
            font_size = 18;
            font_family = theme.fonts.mono;
            position = "0, 120";
            halign = "center";
            valign = "center";
          }
          # Bottom reference bar
          {
            monitor = "";
            text = builtins.concatStringsSep "<br/>" [
              "HTTP:    200 OK   301 Redirect   400 Bad Request   401 Unauth   403 Forbidden   404 Not Found   500 Error"
              "SIGNALS: SIGHUP 1   SIGINT 2   SIGQUIT 3   SIGKILL 9   SIGTERM 15   SIGSTOP 19   SIGCONT 18"
              "CHMOD:   755 rwxr-xr-x   644 rw-r--r--   600 rw-------   777 rwxrwxrwx   400 r--------"
            ];
            color = dim;
            font_size = 10;
            font_family = theme.fonts.mono;
            position = "0, 20";
            halign = "center";
            valign = "bottom";
          }
        ]
        ++ mkSection {
          heading = "── KEYBINDINGS ─────────────────────";
          rows = keybindRows;
          x = 60;
          headingY = -80;
          halign = "left";
        }
        ++ mkSection {
          heading = "── ASCII / HEX ──";
          rows = asciiRows;
          x = -60;
          headingY = -80;
          halign = "right";
        };

      input-field = [{
        monitor = "";
        size = "300, 45";
        outline_thickness = 2;
        dots_size = 0.25;
        dots_spacing = 0.2;
        dots_center = true;
        outer_color = border;
        inner_color = bg;
        font_color = fg;
        fade_on_empty = false;
        placeholder_text = "";
        hide_input = false;
        rounding = 0;
        check_color = green;
        fail_color = red;
        fail_text = "$FAIL";
        capslock_color = accent;
        position = "0, 20";
        halign = "center";
        valign = "center";
      }];
    };
  };
}
