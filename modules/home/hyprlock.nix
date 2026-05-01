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
#     Both panels start at Y=60 (60px from top).
#     Heading at Y=60, body at Y = 60 + headingHeight + gap.
#
#   Bottom bar (valign=bottom, Y=20)

{ config, theme, ... }:

let
  hexToRgba = hex: alpha:
    let
      hexDigit = c:
        if c == "0" then 0 else if c == "1" then 1 else if c == "2" then 2
        else if c == "3" then 3 else if c == "4" then 4 else if c == "5" then 5
        else if c == "6" then 6 else if c == "7" then 7 else if c == "8" then 8
        else if c == "9" then 9 else if c == "a" || c == "A" then 10
        else if c == "b" || c == "B" then 11 else if c == "c" || c == "C" then 12
        else if c == "d" || c == "D" then 13 else if c == "e" || c == "E" then 14
        else if c == "f" || c == "F" then 15 else 0;
      h = builtins.substring 1 6 hex;
      r = hexDigit (builtins.substring 0 1 h) * 16 + hexDigit (builtins.substring 1 1 h);
      g = hexDigit (builtins.substring 2 1 h) * 16 + hexDigit (builtins.substring 3 1 h);
      b = hexDigit (builtins.substring 4 1 h) * 16 + hexDigit (builtins.substring 5 1 h);
    in
    "rgba(${toString r}, ${toString g}, ${toString b}, ${alpha})";

  bg = hexToRgba theme.colors.background "1.0";
  fg = hexToRgba theme.colors.foreground "1.0";
  dim = hexToRgba theme.colors.comment "1.0";
  accent = hexToRgba theme.colors.accent "1.0";
  green = hexToRgba theme.colors.green "1";
  red = hexToRgba theme.colors.red "1";
  border = hexToRgba theme.colors.border "1";
  muted = hexToRgba theme.colors.foregroundDim "1.0";

  mkLabel = text: color: size: x: y: halign: valign: ''
    label {
      monitor     =
      text        = ${builtins.concatStringsSep "<br/>" text}
      color       = ${color}
      font_size   = ${toString size}
      font_family = ${theme.fonts.mono}
      position    = ${toString x}, ${toString y}
      halign      = ${halign}
      valign      = ${valign}
    }
  '';

  # valign=top: Y is distance down from top edge, anchor = top of widget.
  # Heading at headingY, body immediately below: bodyY = headingY + headingH + gap.
  # headingH ≈ 20px for font_size=13.
  mkSection = heading: rows: x: headingY: halign:
    let
      bodyY = headingY - 30; # heading height + gap
    in
    (mkLabel [ heading ] accent 13 x headingY halign "top")
    +
    (mkLabel rows dim 12 x bodyY halign "top");
in
{
  # ── Hypridle ──────────────────────────────────────────────────────────────
  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      lock_cmd         = pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      after_sleep_cmd  = sleep 2 && hyprctl dispatch dpms on
    }

    listener {
      timeout    = 1500
      on-timeout = brightnessctl -s set 10
      on-resume  = brightnessctl -r
    }

    listener {
      timeout    = 1800
      on-timeout = loginctl lock-session
    }

    listener {
      timeout    = 2700
      on-timeout = sh -c '[ "$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)" = "Discharging" ] && systemctl suspend'
    }
  '';

  # ── Hyprlock ──────────────────────────────────────────────────────────────
  xdg.configFile."hypr/hyprlock.conf".text = ''
    general {
      disable_loading_bar = true
      hide_cursor         = true
      grace               = 0
      no_fade_in          = true
      no_fade_out         = true
    }

    # background {
    #   monitor =
    #   color = ${bg}
    # }

    background {
      monitor     =
      path        = $WALLPAPER
      blur_passes = 2
      blur_size   = 0.001
      brightness  = 0.8
    }


    # Clock
    label {
      monitor     =
      text        = $TIME
      color       = ${fg}
      font_size   = 96
      font_family = ${theme.fonts.mono}
      position    = 0, 200
      halign      = center
      valign      = center
    }

    # Date
    label {
      monitor     =
      text        = cmd[update:60000] date '+%A %d %B %Y'
      color       = ${dim}
      font_size   = 18
      font_family = ${theme.fonts.mono}
      position    = 0, 120
      halign      = center
      valign      = center
    }

    # Password input
    input-field {
      monitor           =
      size              = 300, 45
      outline_thickness = 2
      dots_size         = 0.25
      dots_spacing      = 0.2
      dots_center       = true
      outer_color       = ${border}
      inner_color       = ${bg}
      font_color        = ${fg}
      fade_on_empty     = false
      placeholder_text  =
      hide_input        = false
      rounding          = 0
      check_color       = ${green}
      fail_color        = ${red}
      fail_text         = $FAIL
      capslock_color    = ${accent}
      position          = 0, 20
      halign            = center
      valign            = center
    }

    # ── Left — keybindings (top-left, grows downward) ─────────────────────
    ${mkSection "── KEYBINDINGS ─────────────────────" [
        "SUPER + Return       Terminal"
        "SUPER + B            Browser"
        "SUPER + E            Files (Yazi)"
        "SUPER + Space        Launcher"
        "SUPER + O            Notes"
        "SUPER + Q            Kill"
        "SUPER + F            Fullscreen"
        "SUPER + V            Float/tile"
        "SUPER + L            Lock"
        "SUPER + 1-5          Workspace"
        "SUPER + N            Blue light"
        "SUPER + M            Battery"
        "SUPER + Shift + S    Screenshot"
        "SUPER + Shift + E    Exit"
      ] 60 (-80) "left"}

    # ── Right — ASCII/hex (top-right, grows downward) ─────────────────────
    ${mkSection "── ASCII / HEX ──" [
        "32  0x20  SPC"
        "48  0x30  0"
        "65  0x41  A"
        "97  0x61  a"
        "10  0x0A  LF"
        "13  0x0D  CR"
        "27  0x1B  ESC"
        " 9  0x09  TAB"
      ] (-60) (-80) "right"}

    # ── Bottom bar ────────────────────────────────────────────────────────
    ${mkLabel [
        "HTTP:    200 OK   301 Redirect   400 Bad Request   401 Unauth   403 Forbidden   404 Not Found   500 Error"
        "SIGNALS: SIGHUP 1   SIGINT 2   SIGQUIT 3   SIGKILL 9   SIGTERM 15   SIGSTOP 19   SIGCONT 18"
        "CHMOD:   755 rwxr-xr-x   644 rw-r--r--   600 rw-------   777 rwxrwxrwx   400 r--------"
      ] dim 10 0 20 "center" "bottom"}
  '';
}
