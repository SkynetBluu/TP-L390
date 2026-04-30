# modules/home/hyprlock.nix
# Hypridle + Hyprlock — idle daemon and lock screen

{ config, theme, ... }:

let
  # Convert "#RRGGBB" to hyprlock rgba(R, G, B, A)
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

  bg     = hexToRgba theme.colors.background "1.0";
  fg     = hexToRgba theme.colors.foreground "1.0";
  dim    = hexToRgba theme.colors.comment "1.0";
  accent = hexToRgba theme.colors.accent "1.0";
  green  = hexToRgba theme.colors.green "1";
  red    = hexToRgba theme.colors.red "1";
  border = hexToRgba theme.colors.border "1";
  muted  = hexToRgba theme.colors.foregroundDim "1.0";
in
{
  # ── Hypridle ──────────────────────────────────────────────────────────────
  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      lock_cmd         = pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      # Small delay gives Intel GPU/DRM time to reinitialise after s2idle
      after_sleep_cmd  = sleep 2 && hyprctl dispatch dpms on
    }

    # Dim screen after 25 minutes
    listener {
      timeout    = 1500
      on-timeout = brightnessctl -s set 10
      on-resume  = brightnessctl -r
    }

    # Lock screen after 30 minutes
    listener {
      timeout    = 1800
      on-timeout = loginctl lock-session
    }

    # Suspend after 45 minutes — only on battery
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

    background {
      monitor =
      color = ${bg}
    }

    # Clock — large centre
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
      monitor          =
      size             = 300, 45
      outline_thickness = 2
      dots_size        = 0.25
      dots_spacing     = 0.2
      dots_center      = true
      outer_color      = ${border}
      inner_color      = ${bg}
      font_color       = ${fg}
      fade_on_empty    = false
      placeholder_text =
      hide_input       = false
      rounding         = 0
      check_color      = ${green}
      fail_color       = ${red}
      fail_text        = $FAIL
      capslock_color   = ${accent}
      position         = 0, 20
      halign           = center
      valign           = center
    }

    # ── Left side — Hyprland keybindings ──────────────────────────────────

    label {
      monitor     =
      text        = ┌─ HYPRLAND KEYBINDINGS ─┐
      color       = ${accent}
      font_size   = 14
      font_family = ${theme.fonts.mono}
      position    = 60, 350
      halign      = left
      valign      = center
    }

    label { monitor=; text = "SUPER + Return    Terminal";    color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,310; halign=left; valign=center; }
    label { monitor=; text = "SUPER + B         Browser";     color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,285; halign=left; valign=center; }
    label { monitor=; text = "SUPER + E         Files";       color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,260; halign=left; valign=center; }
    label { monitor=; text = "SUPER + Space     Launcher";    color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,235; halign=left; valign=center; }
    label { monitor=; text = "SUPER + Q         Kill";        color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,210; halign=left; valign=center; }
    label { monitor=; text = "SUPER + F         Fullscreen";  color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,185; halign=left; valign=center; }
    label { monitor=; text = "SUPER + 1-5       Workspace";   color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,160; halign=left; valign=center; }
    label { monitor=; text = "SUPER + L         Lock";        color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,135; halign=left; valign=center; }
    label { monitor=; text = "SUPER + N         Blue Light";  color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,110; halign=left; valign=center; }
    label { monitor=; text = "SUPER + M         Battery Mode";color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,85;  halign=left; valign=center; }
    label { monitor=; text = "Print             Screenshot";  color=${dim}; font_size=12; font_family=${theme.fonts.mono}; position=60,60;  halign=left; valign=center; }

    # ── Right side — reference table ──────────────────────────────────────

    label {
      monitor     =
      text        = ┌─ POWERS OF 2 ─┐
      color       = ${accent}
      font_size   = 14
      font_family = ${theme.fonts.mono}
      position    = -60, 350
      halign      = right
      valign      = center
    }

    label { monitor=; text="2⁰=1    2⁴=16    2⁸=256";   color=${dim}; font_size=11; font_family=${theme.fonts.mono}; position=-60,310; halign=right; valign=center; }
    label { monitor=; text="2¹=2    2⁵=32    2⁹=512";   color=${dim}; font_size=11; font_family=${theme.fonts.mono}; position=-60,285; halign=right; valign=center; }
    label { monitor=; text="2²=4    2⁶=64    2¹⁰=1024"; color=${dim}; font_size=11; font_family=${theme.fonts.mono}; position=-60,260; halign=right; valign=center; }
    label { monitor=; text="2³=8    2⁷=128   2¹⁶=65536";color=${dim}; font_size=11; font_family=${theme.fonts.mono}; position=-60,235; halign=right; valign=center; }

    label {
      monitor     =
      text        = ┌─ ASCII / HEX ─┐
      color       = ${accent}
      font_size   = 14
      font_family = ${theme.fonts.mono}
      position    = -60, 190
      halign      = right
      valign      = center
    }

    label { monitor=; text="32=0x20=SPC  65=0x41=A"; color=${dim}; font_size=11; font_family=${theme.fonts.mono}; position=-60,160; halign=right; valign=center; }
    label { monitor=; text="48=0x30=0    97=0x61=a"; color=${dim}; font_size=11; font_family=${theme.fonts.mono}; position=-60,135; halign=right; valign=center; }
    label { monitor=; text="10=0x0A=LF   13=0x0D=CR";color=${dim}; font_size=11; font_family=${theme.fonts.mono}; position=-60,110; halign=right; valign=center; }
    label { monitor=; text="27=0x1B=ESC   9=0x09=TAB";color=${dim}; font_size=11; font_family=${theme.fonts.mono}; position=-60,85;  halign=right; valign=center; }

    # ── Bottom — HTTP codes + signals ─────────────────────────────────────

    label {
      monitor     =
      text        = HTTP: 200 OK │ 301 Redirect │ 400 Bad Request │ 401 Unauthorized │ 403 Forbidden │ 404 Not Found │ 500 Error
      color       = ${muted}
      font_size   = 10
      font_family = ${theme.fonts.mono}
      position    = 0, -280
      halign      = center
      valign      = center
    }

    label {
      monitor     =
      text        = SIGNALS: SIGHUP(1) │ SIGINT(2) │ SIGQUIT(3) │ SIGKILL(9) │ SIGTERM(15) │ SIGSTOP(19) │ SIGCONT(18)
      color       = ${muted}
      font_size   = 10
      font_family = ${theme.fonts.mono}
      position    = 0, -305
      halign      = center
      valign      = center
    }

    label {
      monitor     =
      text        = CHMOD: 755 rwxr-xr-x │ 644 rw-r--r-- │ 600 rw------- │ 777 rwxrwxrwx │ 400 r--------
      color       = ${muted}
      font_size   = 10
      font_family = ${theme.fonts.mono}
      position    = 0, -330
      halign      = center
      valign      = center
    }
  '';
}
