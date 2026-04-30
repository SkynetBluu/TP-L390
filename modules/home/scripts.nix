# modules/home/scripts.nix
# Hyprland helper scripts — battery, blue light, performance, PiP, wifi, etc.

{ pkgs, inputs, ... }:

let
  hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

  # ── Blue light filter ────────────────────────────────────────────────────

  bluelight-toggle = pkgs.writeShellScriptBin "bluelight-toggle" ''
    set -euo pipefail
    STATE_FILE="$HOME/.config/bluelight-state"
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "off")
    case "$CURRENT" in
      off|6500) NEXT="5500"; TEMP=5500; DESC="󰖨  Level 1 (5500K - Afternoon)" ;;
      5500)     NEXT="4500"; TEMP=4500; DESC="󰖨  Level 2 (4500K - Sunset)" ;;
      4500)     NEXT="3500"; TEMP=3500; DESC="󰖨  Level 3 (3500K - Golden hour)" ;;
      3500)     NEXT="2500"; TEMP=2500; DESC="󰖨  Level 4 (2500K - Candlelight)" ;;
      2500)     NEXT="2000"; TEMP=2000; DESC="󱩌  Level 5 (2000K - Late night)" ;;
      2000)     NEXT="1500"; TEMP=1500; DESC="󱩌  Level 6 (1500K - Pre-sleep)" ;;
      1500)     NEXT="1200"; TEMP=1200; DESC="󱩌  Level 7 (1200K - Maximum)" ;;
      1200)     NEXT="1000"; TEMP=1000; DESC="󱩌  Level 8 (1000K - Ultra deep)" ;;
      1000)     NEXT="off";  TEMP=0;    DESC="󰖙  Filter Off" ;;
      *)        NEXT="5500"; TEMP=5500; DESC="󰖨  Level 1 (5500K - Afternoon)" ;;
    esac
    ${pkgs.procps}/bin/pkill -TERM hyprsunset 2>/dev/null && sleep 0.2 || true
    ${pkgs.procps}/bin/pkill -KILL hyprsunset 2>/dev/null || true
    if [ "$NEXT" != "off" ]; then
      ${pkgs.hyprsunset}/bin/hyprsunset -t $TEMP &
      disown
    fi
    echo "$NEXT" > "$STATE_FILE"
    ${pkgs.libnotify}/bin/notify-send -t 2000 "Blue Light Filter" "$DESC" -i "weather-clear-night"
  '';

  bluelight-off = pkgs.writeShellScriptBin "bluelight-off" ''
    ${pkgs.procps}/bin/pkill hyprsunset 2>/dev/null || true
    echo "off" > "$HOME/.config/bluelight-state"
    ${pkgs.libnotify}/bin/notify-send -t 1500 "Blue Light Filter" "󰖙  Disabled" -i "weather-clear"
  '';

  bluelight-auto = pkgs.writeShellScriptBin "bluelight-auto" ''
    STATE_FILE="$HOME/.config/bluelight-state"
    HOUR=$(date +%H)
    if [ "$HOUR" -ge 20 ] || [ "$HOUR" -lt 7 ]; then
      if ${pkgs.procps}/bin/pgrep -x hyprsunset > /dev/null; then exit 0; fi
      echo "2000" > "$STATE_FILE"
      ${pkgs.hyprsunset}/bin/hyprsunset -t 2000 &
      disown
    fi
  '';

  # ── Performance mode ─────────────────────────────────────────────────────

  perf-mode = pkgs.writeShellScriptBin "perf-mode" ''
    set -euo pipefail
    STATE_FILE="$HOME/.config/perf-mode-state"
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "balanced")
    case "$CURRENT" in
      battery)
        hyprctl keyword animations:enabled true
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:glow:enabled false
        echo "balanced" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "⚖️ Balanced Mode" "Animations ON, moderate savings" -i "battery-good"
        ;;
      balanced)
        hyprctl keyword animations:enabled true
        hyprctl keyword misc:render_unfocused_fps 60
        hyprctl keyword decoration:blur:enabled true
        hyprctl keyword decoration:shadow:enabled true
        echo "max" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "🚀 Max Performance" "All effects ON" -i "video-display"
        ;;
      max|*)
        hyprctl keyword animations:enabled false
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:blur:enabled false
        hyprctl keyword decoration:shadow:enabled false
        echo "battery" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "🔋 Battery Saver" "All effects OFF" -i "battery-caution"
        ;;
    esac
  '';

  perf-mode-daemon = pkgs.writeShellScriptBin "perf-mode-daemon" ''
    STATE_FILE="$HOME/.config/perf-mode-state"
    LAST_STATUS=""
    apply_mode() {
      local status="$1"
      if [ "$status" = "Discharging" ] && [ "$LAST_STATUS" != "Discharging" ]; then
        hyprctl keyword animations:enabled false
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:blur:enabled false
        hyprctl keyword decoration:shadow:enabled false
        echo "battery" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "Battery Mode" "󰂃 Battery saver auto-enabled" -i "battery-good"
        LAST_STATUS="$status"
      elif [ "$status" != "Discharging" ] && [ "$LAST_STATUS" = "Discharging" ]; then
        hyprctl keyword animations:enabled true
        hyprctl keyword misc:render_unfocused_fps 10
        echo "balanced" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "AC Power" "󰂄 Balanced mode restored" -i "battery-full-charging"
        LAST_STATUS="$status"
      elif [ -z "$LAST_STATUS" ]; then
        LAST_STATUS="$status"
      fi
    }
    if [ -f /sys/class/power_supply/BAT0/status ]; then
      apply_mode "$(cat /sys/class/power_supply/BAT0/status)"
    fi
    ${pkgs.upower}/bin/upower --monitor-detail | while read -r line; do
      if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "state:"; then
        state=$(echo "$line" | ${pkgs.gnused}/bin/sed 's/.*state:\s*//' | ${pkgs.findutils}/bin/xargs)
        case "$state" in
          discharging) apply_mode "Discharging" ;;
          charging|fully-charged) apply_mode "Charging" ;;
        esac
      fi
    done
  '';

  # ── Battery mode (ThinkPad charge thresholds) ────────────────────────────

  battery-mode = pkgs.writeShellScriptBin "battery-mode" ''
    STATE_FILE="$HOME/.config/battery-mode-state"
    CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "conservation")
    case "$CURRENT_MODE" in
      conservation) NEXT_MODE="balanced";     START=75; STOP=80;  TITLE="Balanced Mode";      DESC="Charge: 75-80% (daily use)"      ;;
      balanced)     NEXT_MODE="full";         START=95; STOP=100; TITLE="Full Mode";           DESC="Charge: 95-100% (travel)"        ;;
      full)         NEXT_MODE="conservation"; START=55; STOP=60;  TITLE="Conservation Mode";   DESC="Charge: 55-60% (always plugged)" ;;
      *)            NEXT_MODE="balanced";     START=75; STOP=80;  TITLE="Balanced Mode";       DESC="Charge: 75-80% (daily use)"      ;;
    esac
    if command -v tlp &> /dev/null; then
      sudo tlp setcharge $START $STOP BAT0 && \
        echo "$NEXT_MODE" > "$STATE_FILE" && \
        ${pkgs.libnotify}/bin/notify-send -t 3000 "$TITLE" "$DESC" || \
        ${pkgs.libnotify}/bin/notify-send -t 3000 "Battery Error" "Failed to change mode" -i "dialog-error"
    fi
  '';

  # ── Touchpad toggle ──────────────────────────────────────────────────────

  touchpad-toggle = pkgs.writeShellScriptBin "touchpad-toggle" ''
    set -euo pipefail
    DEVICES_JSON=$(${hyprlandPkg}/bin/hyprctl devices -j)
    DEVICE=$(echo "$DEVICES_JSON" | ${pkgs.jq}/bin/jq -r '
      .mice | map(select((.name // "" | ascii_downcase | test("touchpad")))) | .[0].name // empty')
    if [ -z "$DEVICE" ]; then
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "No touchpad detected" -i "dialog-error"
      exit 1
    fi
    STATE=$(echo "$DEVICES_JSON" | ${pkgs.jq}/bin/jq -r --arg d "$DEVICE" '
      .mice[] | select(.name == $d) | if .enabled == false then "false" else "true" end')
    if [ "$STATE" = "true" ]; then
      ${hyprlandPkg}/bin/hyprctl keyword "device[$DEVICE]:enabled" false
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "Disabled" -i "input-touchpad"
    else
      ${hyprlandPkg}/bin/hyprctl keyword "device[$DEVICE]:enabled" true
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "Enabled" -i "input-touchpad"
    fi
  '';

  # ── Wi-Fi management ─────────────────────────────────────────────────────

  wifi-manage = pkgs.writeShellScriptBin "wifi-manage" ''
    set -euo pipefail
    ACTION="''${1:-toggle}"
    case "$ACTION" in
      toggle)
        STATUS=$(nmcli radio wifi)
        if [ "$STATUS" = "enabled" ]; then
          nmcli radio wifi off
          ${pkgs.libnotify}/bin/notify-send -t 2000 "WiFi" "󰤭  Disabled" -i "network-wireless-offline"
        else
          nmcli radio wifi on
          ${pkgs.libnotify}/bin/notify-send -t 2000 "WiFi" "󰤨  Enabled" -i "network-wireless"
        fi
        ;;
      reconnect)
        ${pkgs.libnotify}/bin/notify-send -t 2000 "WiFi" "󰤩  Reconnecting..." -i "network-wireless-acquiring"
        nmcli radio wifi off && sleep 1 && nmcli radio wifi on && sleep 3
        if nmcli -t -f STATE general | grep -q "connected"; then
          SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep "^yes" | cut -d: -f2)
          ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless"
        else
          ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Not connected" -i "network-wireless-offline"
        fi
        ;;
      scan)
        ${pkgs.libnotify}/bin/notify-send -t 1500 "WiFi" "󰤩  Scanning..." -i "network-wireless-acquiring"
        nmcli radio wifi on 2>/dev/null || true && sleep 1
        NETWORKS=$(nmcli -t -f SIGNAL,SECURITY,SSID dev wifi list --rescan yes 2>/dev/null | \
          ${pkgs.gawk}/bin/awk -F: 'NF>=3 && $3!="" {
            sig=$1; sec=$2; ssid=$3;
            icon=(sig+0>=75)?"󰤨":(sig+0>=50)?"󰤥":(sig+0>=25)?"󰤢":"󰤟";
            lock=(sec!=""&&sec!="--")?"󰌾":"󰌿";
            if(!seen[ssid]++) printf "%s %s %s (%s%%)\n",icon,lock,ssid,sig}')
        if [ -z "$NETWORKS" ]; then
          ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "No networks found" -i "network-wireless-offline"
          exit 1
        fi
        CHOSEN=$(echo "$NETWORKS" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "WiFi Network" --width 400 --height 300) || exit 0
        SSID=$(echo "$CHOSEN" | ${pkgs.gnused}/bin/sed 's/^[^ ]* [^ ]* //' | ${pkgs.gnused}/bin/sed 's/ ([0-9]*%)$//')
        if nmcli -t -f NAME connection show | grep -qx "$SSID"; then
          nmcli connection up "$SSID" && \
            ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless" || \
            ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Failed" -i "network-wireless-offline"
        else
          SECURITY=$(nmcli -t -f SSID,SECURITY dev wifi list | grep "^$SSID:" | head -1 | cut -d: -f2)
          if [ -n "$SECURITY" ] && [ "$SECURITY" != "--" ]; then
            PASSWORD=$(echo "" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Password for $SSID" --password --width 400 --height 100) || exit 0
            nmcli device wifi connect "$SSID" password "$PASSWORD" && \
              ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless" || \
              ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Wrong password?" -i "network-wireless-offline"
          else
            nmcli device wifi connect "$SSID" && \
              ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤨  Connected to $SSID (open)" -i "network-wireless" || \
              ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Failed" -i "network-wireless-offline"
          fi
        fi
        ;;
    esac
  '';

  # ── Quick notes ──────────────────────────────────────────────────────────

  quick-notes = pkgs.writeShellScriptBin "quick-notes" ''
    set -euo pipefail
    NOTES_DIR="$HOME/Notes"
    mkdir -p "$NOTES_DIR"
    DATE=$(date +%Y-%m-%d)
    TIME=$(date +%H-%M-%S)
    NOTE_FILE="$NOTES_DIR/quick-$DATE-$TIME.md"
    cat > "$NOTE_FILE" << TEMPLATE
    # Quick Note - $(date '+%Y-%m-%d %H:%M')
    ---
    TEMPLATE
    alacritty --class="quick-notes" -e nvim "+normal G" "$NOTE_FILE"
  '';

  # ── System info ──────────────────────────────────────────────────────────

  sysinfo-panel = pkgs.writeShellScriptBin "sysinfo-panel" ''
    set -euo pipefail
    HOSTNAME=$(hostname)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p | sed 's/up //')
    CPU_MODEL=$(${pkgs.gawk}/bin/awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo)
    CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | ${pkgs.gawk}/bin/awk '{printf "%.1f", $1/1000}')
    MEM_INFO=$(free -h | ${pkgs.gawk}/bin/awk '/^Mem:/{print $3 "/" $2}')
    MEM_PERCENT=$(free | ${pkgs.gawk}/bin/awk '/^Mem:/{printf "%.0f", $3/$2*100}')
    DISK_INFO=$(df -h / | ${pkgs.gawk}/bin/awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
      BAT_CAP=$(cat /sys/class/power_supply/BAT0/capacity)
      BAT_STATUS=$(cat /sys/class/power_supply/BAT0/status)
      BATTERY="$BAT_CAP% ($BAT_STATUS)"
    else
      BATTERY="N/A"
    fi
    NET_IFACE=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gawk}/bin/awk '/default/{print $5; exit}')
    NET_IP=$(${pkgs.iproute2}/bin/ip -4 addr show "$NET_IFACE" 2>/dev/null | ${pkgs.gawk}/bin/awk '/inet /{print $2}' | cut -d'/' -f1)
    # Intel UHD 620 doesn't expose GPU usage via sysfs — use intel_gpu_top if available
    GPU_USAGE="N/A"
    BLUELIGHT_STATE=$(cat "$HOME/.config/bluelight-state" 2>/dev/null || echo "off")
    [ "$BLUELIGHT_STATE" = "off" ] && BLUELIGHT="Off" || BLUELIGHT="$BLUELIGHT_STATE K"
    INFO="<b>󰌢 $HOSTNAME</b>
    Kernel: $KERNEL | Uptime: $UPTIME

    <b>󰻠 CPU</b>  $CPU_MODEL @ $CPU_TEMP°C
    <b>󰍛 RAM</b>  $MEM_INFO ($MEM_PERCENT%)
    <b>󰋊 Disk</b>  $DISK_INFO
    <b>󰂄 Battery</b>  $BATTERY
    <b>󰢮 GPU</b>  Intel UHD 620 ($GPU_USAGE)
    <b>󰖩 Network</b>  $NET_IP
    <b>󰖨 Filter</b>  $BLUELIGHT"
    ${pkgs.libnotify}/bin/notify-send -t 10000 "System Info" "$INFO" -i "utilities-system-monitor"
  '';

  # ── hypr-current-workspace-launch ────────────────────────────────────────

  hypr-current-workspace-launch = pkgs.writeShellScriptBin "hypr-current-workspace-launch" ''
    set -euo pipefail
    if [ "$#" -lt 2 ]; then echo "usage: hypr-current-workspace-launch <class-regex> <command> [args...]" >&2; exit 64; fi
    CLASS_RE="$1"; shift
    if [ "$#" -gt 1 ]; then exec "$@"; fi
    JQ="${pkgs.jq}/bin/jq"
    if ! CLIENTS_JSON=$(hyprctl clients -j 2>/dev/null); then exec "$@"; fi
    WIN=$(printf '%s\n' "$CLIENTS_JSON" | "$JQ" -r --arg class_re "$CLASS_RE" '
      [.[] | select(((.class//"") | test($class_re)) or ((.initialClass//"") | test($class_re))) | select((.mapped//true)==true)]
      | sort_by(if ((.focusHistoryID//999999)<0) then 999999 else (.focusHistoryID//999999) end)
      | .[0].address // empty')
    if [ -z "$WIN" ]; then exec "$@"; fi
    ACTIVE_WS=$(hyprctl activeworkspace -j 2>/dev/null | "$JQ" -r '.id // empty' || true)
    case "$ACTIVE_WS" in ""|null|-*) ;; *) hyprctl dispatch movetoworkspacesilent "$ACTIVE_WS,address:$WIN" >/dev/null 2>&1 || true ;; esac
    hyprctl dispatch focuswindow "address:$WIN" >/dev/null 2>&1 || true
  '';

in
{
  home.packages = [
    bluelight-toggle
    bluelight-off
    bluelight-auto
    perf-mode
    perf-mode-daemon
    battery-mode
    touchpad-toggle
    wifi-manage
    quick-notes
    sysinfo-panel
    hypr-current-workspace-launch
    # Runtime deps for scripts
    pkgs.hyprsunset
    pkgs.upower
    pkgs.wofi
    pkgs.socat
    pkgs.libnotify
    pkgs.iproute2
    pkgs.procps
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.findutils
    pkgs.jq
  ];

  # Start perf-mode-daemon and bluelight-auto at login
  systemd.user.services.perf-mode-daemon = {
    Unit    = { Description = "Battery-aware Hyprland performance daemon"; After = [ "graphical-session.target" ]; };
    Service = { ExecStart = "${perf-mode-daemon}/bin/perf-mode-daemon"; Restart = "on-failure"; };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
