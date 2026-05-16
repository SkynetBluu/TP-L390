# modules/home/scripts.nix
# Hyprland helper scripts — battery, blue light, performance, PiP, wifi, etc.

{ pkgs, inputs, ... }:

let
  hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

  # Single source of truth for the rofi binary — change this in one place
  # to swap launchers (e.g. back to pkgs.rofi, or to a fork).
  rofiBin = "${pkgs.rofi}/bin/rofi";

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
    if ${pkgs.procps}/bin/pgrep -x hyprsunset > /dev/null; then exit 0; fi
    echo "2000" > "$STATE_FILE"
    ${pkgs.hyprsunset}/bin/hyprsunset -t 2000 &
    disown
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
    # Apply settings for the current status. On the first call (LAST_STATUS
    # empty) we apply but suppress the notification — the user didn't just
    # plug/unplug, they just logged in. On subsequent calls a transition
    # fires a notification.
    apply_mode() {
      local status="$1"
      [ "$status" = "$LAST_STATUS" ] && return
      local first_call=0
      [ -z "$LAST_STATUS" ] && first_call=1

      if [ "$status" = "Discharging" ]; then
        hyprctl keyword animations:enabled false
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:blur:enabled false
        hyprctl keyword decoration:shadow:enabled false
        echo "battery" > "$STATE_FILE"
        [ "$first_call" = 0 ] && ${pkgs.libnotify}/bin/notify-send -t 2000 "Battery Mode" "󰂃 Battery saver auto-enabled" -i "battery-good"
      else
        hyprctl keyword animations:enabled true
        hyprctl keyword misc:render_unfocused_fps 10
        echo "balanced" > "$STATE_FILE"
        [ "$first_call" = 0 ] && ${pkgs.libnotify}/bin/notify-send -t 2000 "AC Power" "󰂄 Balanced mode restored" -i "battery-full-charging"
      fi
      LAST_STATUS="$status"
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

  # The system boot default (tlp 75/80 in configuration.nix) matches the
  # `balanced` case below — so when the state file is missing we treat the
  # current state as balanced, and Super+M cycles to `full` on first press.
  battery-mode = pkgs.writeShellScriptBin "battery-mode" ''
    STATE_FILE="$HOME/.config/battery-mode-state"
    CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "balanced")
    case "$CURRENT_MODE" in
      conservation) NEXT_MODE="balanced";     START=75; STOP=80;  TITLE="Balanced Mode";      DESC="Charge: 75-80% (daily use)"      ;;
      balanced)     NEXT_MODE="full";         START=95; STOP=100; TITLE="Full Mode";           DESC="Charge: 95-100% (travel)"        ;;
      full)         NEXT_MODE="conservation"; START=55; STOP=60;  TITLE="Conservation Mode";   DESC="Charge: 55-60% (always plugged)" ;;
      *)            NEXT_MODE="full";         START=95; STOP=100; TITLE="Full Mode";           DESC="Charge: 95-100% (travel)"        ;;
    esac
    sudo tlp setcharge $START $STOP BAT0 && \
      echo "$NEXT_MODE" > "$STATE_FILE" && \
      ${pkgs.libnotify}/bin/notify-send -t 3000 "$TITLE" "$DESC" || \
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Battery Error" "Failed to change mode" -i "dialog-error"
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

    ROFI="${rofiBin}"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"

    ACTION="''${1:-toggle}"
    case "$ACTION" in
      toggle)
        STATUS=$(nmcli radio wifi)
        if [ "$STATUS" = "enabled" ]; then
          nmcli radio wifi off
          "$NOTIFY" -t 2000 "WiFi" "󰤭  Disabled" -i "network-wireless-offline"
        else
          nmcli radio wifi on
          "$NOTIFY" -t 2000 "WiFi" "󰤨  Enabled" -i "network-wireless"
        fi
        ;;
      reconnect)
        "$NOTIFY" -t 2000 "WiFi" "󰤩  Reconnecting..." -i "network-wireless-acquiring"
        nmcli radio wifi off && sleep 1 && nmcli radio wifi on && sleep 3
        if nmcli -t -f STATE general | ${pkgs.gnugrep}/bin/grep -q "connected"; then
          SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | ${pkgs.gnugrep}/bin/grep "^yes" | cut -d: -f2)
          "$NOTIFY" -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless"
        else
          "$NOTIFY" -t 3000 "WiFi" "󰤭  Not connected" -i "network-wireless-offline"
        fi
        ;;
      scan)
        "$NOTIFY" -t 1500 "WiFi" "󰤩  Scanning..." -i "network-wireless-acquiring"
        nmcli radio wifi on 2>/dev/null || true && sleep 1

        # Build two parallel arrays:
        #   DISPLAY[i] — what rofi shows the user (icon + lock + ssid + signal)
        #   SSIDS[i]   — the corresponding bare SSID
        # nmcli output is colon-separated; backslash-escape any colons in SSIDs (`-e no` keeps them literal).
        SCAN=$(nmcli -t -e no -f SIGNAL,SECURITY,SSID dev wifi list --rescan yes 2>/dev/null)

        if [ -z "$SCAN" ]; then
          "$NOTIFY" -t 3000 "WiFi" "No networks found" -i "network-wireless-offline"
          exit 1
        fi

        DISPLAY=""
        SSIDS=()
        seen=""
        while IFS= read -r line; do
          [ -z "$line" ] && continue
          # Split on first two colons; rest is the SSID (may contain colons).
          sig="''${line%%:*}"
          rest="''${line#*:}"
          sec="''${rest%%:*}"
          ssid="''${rest#*:}"
          [ -z "$ssid" ] && continue
          # Dedupe SSIDs (multiple BSSIDs report separately)
          case " $seen " in *" $ssid "*) continue ;; esac
          seen="$seen $ssid"

          if [ "$sig" -ge 75 ]; then icon="󰤨"
          elif [ "$sig" -ge 50 ]; then icon="󰤥"
          elif [ "$sig" -ge 25 ]; then icon="󰤢"
          else icon="󰤟"
          fi
          if [ -n "$sec" ] && [ "$sec" != "--" ]; then lock="󰌾"; else lock="󰌿"; fi

          DISPLAY="$DISPLAY$icon $lock $ssid ($sig%)"$'\n'
          SSIDS+=("$ssid")
        done <<< "$SCAN"

        DISPLAY="''${DISPLAY%$'\n'}"

        if [ "''${#SSIDS[@]}" -eq 0 ]; then
          "$NOTIFY" -t 3000 "WiFi" "No networks found" -i "network-wireless-offline"
          exit 1
        fi

        IDX=$(printf '%s\n' "$DISPLAY" | "$ROFI" \
          -dmenu \
          -i \
          -p "WiFi" \
          -format i \
          -no-custom \
          -theme-str 'window {width: 480px;}' \
          -theme-str 'listview {lines: 8; scrollbar: false;}' \
          -theme-str 'textbox-prompt-colon {enabled: false;}' \
          || true)

        [ -z "$IDX" ] && exit 0
        SSID="''${SSIDS[$IDX]}"

        # Already saved → just connect by name
        if nmcli -t -f NAME connection show | ${pkgs.gnugrep}/bin/grep -qx "$SSID"; then
          if nmcli connection up "$SSID" >/dev/null 2>&1; then
            "$NOTIFY" -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless"
          else
            "$NOTIFY" -t 3000 "WiFi" "󰤭  Failed" -i "network-wireless-offline"
          fi
          exit 0
        fi

        # Find security level for this SSID
        SECURITY=$(nmcli -t -e no -f SSID,SECURITY dev wifi list | ${pkgs.gnugrep}/bin/grep -F "$SSID:" | head -1 | ${pkgs.gnused}/bin/sed "s/^$SSID://")

        if [ -n "$SECURITY" ] && [ "$SECURITY" != "--" ]; then
          # rofi -password masks input with bullets
          PASSWORD=$("$ROFI" \
            -dmenu \
            -password \
            -p "Password for $SSID" \
            -theme-str 'window {width: 480px;}' \
            -theme-str 'listview {enabled: false;}' \
            -theme-str 'textbox-prompt-colon {enabled: false;}' \
            < /dev/null \
            || true)
          [ -z "$PASSWORD" ] && exit 0
          if nmcli device wifi connect "$SSID" password "$PASSWORD" >/dev/null 2>&1; then
            "$NOTIFY" -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless"
          else
            "$NOTIFY" -t 3000 "WiFi" "󰤭  Wrong password?" -i "network-wireless-offline"
          fi
        else
          if nmcli device wifi connect "$SSID" >/dev/null 2>&1; then
            "$NOTIFY" -t 3000 "WiFi" "󰤨  Connected to $SSID (open)" -i "network-wireless"
          else
            "$NOTIFY" -t 3000 "WiFi" "󰤭  Failed" -i "network-wireless-offline"
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
    # Open at the last line (helix `:N` suffix). Press `o` to open a new line below.
    LINES=$(wc -l < "$NOTE_FILE")
    ghostty --class="quick-notes" -e hx "$NOTE_FILE:$LINES"
  '';

  # ── System info ──────────────────────────────────────────────────────────

  sysinfo-panel = pkgs.writeShellScriptBin "sysinfo-panel" ''
    set -euo pipefail
    HOSTNAME=$(hostname)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p | sed 's/up //')
    CPU_MODEL=$(${pkgs.gawk}/bin/awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo)
    # hwmonN indices aren't stable; glob the platform-rooted path instead
    shopt -s nullglob
    HWMON_FILES=(/sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input)
    shopt -u nullglob
    if [ "''${#HWMON_FILES[@]}" -gt 0 ]; then
      CPU_TEMP=$(${pkgs.gawk}/bin/awk '{printf "%.1f°C", $1/1000}' "''${HWMON_FILES[0]}")
    else
      CPU_TEMP="N/A"
    fi
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
    GPU_USAGE="N/A"
    BLUELIGHT_STATE=$(cat "$HOME/.config/bluelight-state" 2>/dev/null || echo "off")
    [ "$BLUELIGHT_STATE" = "off" ] && BLUELIGHT="Off" || BLUELIGHT="$BLUELIGHT_STATE K"

    TMPFILE="/tmp/sysinfo-panel-rows"
        cat > "$TMPFILE" << EOF
    󰌢   Host        $HOSTNAME
    󰣇   Kernel      $KERNEL
    󱦟   Uptime      $UPTIME
    󰻠   CPU         $CPU_MODEL
    󰔏   Temp        $CPU_TEMP
    󰍛   RAM         $MEM_INFO ($MEM_PERCENT%)
    󰋊   Disk        $DISK_INFO
    󰂄   Battery     $BATTERY
    󰢮   GPU         Intel UHD 620 ($GPU_USAGE)
    󰖩   Network     $NET_IP ($NET_IFACE)
    󰖨   Filter      $BLUELIGHT
    EOF

    ${rofiBin} \
      -dmenu \
      -p "󰋊 System" \
      -input "$TMPFILE" \
      -theme-str 'window {width: 680px;}' \
      -theme-str 'listview {lines: 11; scrollbar: false; fixed-height: true;}' \
      -theme-str 'entry {enabled: false;}' \
      -theme-str 'textbox-prompt-colon {enabled: false;}' \
      || true
  '';

  # ── Power menu ───────────────────────────────────────────────────────────
  # Rofi-based power menu invoked from waybar. Two-step (pick action, confirm)
  # for everything except Lock, which fires immediately — locking is harmless
  # and the friction isn't worth it.
  # Logout uses `uwsm stop` (canonical under UWSM — `hyprctl dispatch exit`
  # is discouraged with UWSM and can leave a black screen).
  # Suspend/reboot/poweroff go through systemctl so systemd brings down the
  # graphical session cleanly.

  power-menu = pkgs.writeShellScriptBin "power-menu" ''
        set -euo pipefail

        ROFI="${rofiBin}"

        # Step 1: action picker. Search field hidden — pick by arrow keys/click only.
        OPTIONS="󰌾  Lock
    󰍃  Logout
    󰒲  Suspend
    󰜉  Reboot
    󰐥  Shutdown"

        CHOICE=$(printf '%s\n' "$OPTIONS" | "$ROFI" \
          -dmenu \
          -p "󰐥 Power" \
          -no-custom \
          -theme-str 'window {width: 280px;}' \
          -theme-str 'listview {lines: 5; scrollbar: false; fixed-height: true;}' \
          -theme-str 'entry {enabled: false;}' \
          -theme-str 'textbox-prompt-colon {enabled: false;}' \
          || true)

        [ -z "$CHOICE" ] && exit 0

        # Strip leading icon + spaces to get the bare action name
        ACTION=$(printf '%s' "$CHOICE" | ${pkgs.gnused}/bin/sed 's/^[^ ]*  *//')

        # Lock is harmless — fire immediately, skip confirmation.
        if [ "$ACTION" = "Lock" ]; then
          exec loginctl lock-session
        fi

        # Step 2: confirm everything else. "No" first so accidental Enter cancels.
        CONFIRM=$(printf 'No\nYes' | "$ROFI" \
          -dmenu \
          -p "$ACTION?" \
          -no-custom \
          -theme-str 'window {width: 240px;}' \
          -theme-str 'listview {lines: 2; scrollbar: false; fixed-height: true;}' \
          -theme-str 'entry {enabled: false;}' \
          -theme-str 'textbox-prompt-colon {enabled: false;}' \
          || true)

        [ "$CONFIRM" != "Yes" ] && exit 0

        case "$ACTION" in
          Logout)   exec ${pkgs.uwsm}/bin/uwsm stop ;;
          Suspend)  exec systemctl suspend ;;
          Reboot)   exec systemctl reboot ;;
          Shutdown) exec systemctl poweroff ;;
        esac
  '';

  # ── USB disk manager ─────────────────────────────────────────────────────

  usb-menu = pkgs.writeShellScriptBin "usb-menu" ''
    set -euo pipefail

    ROFI="${rofiBin}"
    JQ="${pkgs.jq}/bin/jq"
    LSBLK="${pkgs.util-linux}/bin/lsblk"
    UDISKSCTL="${pkgs.udisks2}/bin/udisksctl"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"

    refresh_waybar() { ${pkgs.procps}/bin/pkill -RTMIN+8 waybar 2>/dev/null || true; }

    # Discover USB partitions: device|size|label|fstype|mountpoint
    ENTRIES=$(
      "$LSBLK" -J -p -o NAME,TYPE,TRAN,SIZE,MOUNTPOINT,LABEL,FSTYPE 2>/dev/null \
        | "$JQ" -r '
            .blockdevices[]
            | select(.type == "disk" and .tran == "usb")
            | (.children // [])[]
            | select(.type == "part")
            | "\(.name)|\(.size)|\(.label // "(no label)")|\(.fstype // "?")|\(.mountpoint // "")"'
    )

    if [ -z "$ENTRIES" ]; then
      "$NOTIFY" -t 2000 "USB" "No USB partitions detected" -i "drive-removable-media"
      exit 0
    fi

    # Build display lines (icon + label + size + status). Order matches $ENTRIES.
    DISPLAY=""
    while IFS='|' read -r dev size label fstype mount; do
      if [ -n "$mount" ]; then
        DISPLAY="$DISPLAY●  $label   $size $fstype   →  $mount"$'\n'
      else
        DISPLAY="$DISPLAY○  $label   $size $fstype   (not mounted)"$'\n'
      fi
    done <<< "$ENTRIES"
    DISPLAY="''${DISPLAY%$'\n'}"

    # rofi -format i returns the 0-based index of the selection.
    # No need to parse the chosen line — just use the index to look up $ENTRIES.
    IDX=$(printf '%s\n' "$DISPLAY" | "$ROFI" \
      -dmenu \
      -i \
      -p "USB" \
      -format i \
      -no-custom \
      -theme-str 'window {width: 600px;}' \
      -theme-str 'listview {lines: 6; scrollbar: false; fixed-height: true;}' \
      -theme-str 'textbox-prompt-colon {enabled: false;}' \
      || true)

    [ -z "$IDX" ] && exit 0

    # Pull the chosen entry by index (sed is 1-based, so add 1)
    DETAILS=$(printf '%s\n' "$ENTRIES" | ${pkgs.gnused}/bin/sed -n "$((IDX+1))p")
    IFS='|' read -r DEV SIZE LABEL FSTYPE MOUNT <<< "$DETAILS"

    # Action menu — different choices depending on mount state
    if [ -n "$MOUNT" ]; then
      ACTIONS=$'Open in Nemo\nUnmount\nEject (unmount + power off)\nCancel'
      LINES=4
    else
      ACTIONS=$'Mount\nMount and open\nDo not mount\nCancel'
      LINES=4
    fi

    ACTION=$(printf '%s' "$ACTIONS" | "$ROFI" \
      -dmenu \
      -i \
      -p "$LABEL" \
      -no-custom \
      -theme-str "window {width: 360px;}" \
      -theme-str "listview {lines: $LINES; scrollbar: false; fixed-height: true;}" \
      -theme-str 'textbox-prompt-colon {enabled: false;}' \
      || true)

    case "$ACTION" in
      "Mount")
        OUT=$("$UDISKSCTL" mount -b "$DEV" 2>&1) || {
          "$NOTIFY" -u critical -t 4000 "Mount failed: $LABEL" "$OUT" -i "dialog-error"
          exit 1
        }
        MP=$(printf '%s' "$OUT" | ${pkgs.gnugrep}/bin/grep -oP 'at \K[^.]+' | ${pkgs.gnused}/bin/sed 's/[[:space:]]*$//')
        "$NOTIFY" -t 3000 "Mounted $LABEL" "$MP" -i "drive-removable-media"
        refresh_waybar
        ;;
      "Mount and open")
        OUT=$("$UDISKSCTL" mount -b "$DEV" 2>&1) || {
          "$NOTIFY" -u critical -t 4000 "Mount failed: $LABEL" "$OUT" -i "dialog-error"
          exit 1
        }
        MP=$(printf '%s' "$OUT" | ${pkgs.gnugrep}/bin/grep -oP 'at \K[^.]+' | ${pkgs.gnused}/bin/sed 's/[[:space:]]*$//')
        "$NOTIFY" -t 3000 "Mounted $LABEL" "$MP" -i "drive-removable-media"
        refresh_waybar
        nemo "$MP" >/dev/null 2>&1 &
        disown
        ;;
      "Open in Nemo")
        nemo "$MOUNT" >/dev/null 2>&1 &
        disown
        ;;
      "Unmount")
        OUT=$("$UDISKSCTL" unmount -b "$DEV" 2>&1) || {
          "$NOTIFY" -u critical -t 4000 "Unmount failed: $LABEL" "$OUT" -i "dialog-error"
          exit 1
        }
        "$NOTIFY" -t 2000 "Unmounted $LABEL" "" -i "media-eject"
        refresh_waybar
        ;;
      "Eject (unmount + power off)")
        OUT=$("$UDISKSCTL" unmount -b "$DEV" 2>&1) || {
          "$NOTIFY" -u critical -t 4000 "Unmount failed: $LABEL" "$OUT" -i "dialog-error"
          exit 1
        }
        PARENT="/dev/$("$LSBLK" -no PKNAME "$DEV" | head -1)"
        "$UDISKSCTL" power-off -b "$PARENT" >/dev/null 2>&1 || true
        "$NOTIFY" -t 3000 "Ejected $LABEL" "Safe to remove" -i "media-eject"
        refresh_waybar
        ;;
      *)
        exit 0
        ;;
    esac
  '';

  usb-monitor = pkgs.writeShellScriptBin "usb-monitor" ''
    set -uo pipefail

    GDBUS="${pkgs.glib}/bin/gdbus"
    LSBLK="${pkgs.util-linux}/bin/lsblk"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    USB_MENU="${usb-menu}/bin/usb-menu"

    refresh_waybar() { ${pkgs.procps}/bin/pkill -RTMIN+8 waybar 2>/dev/null || true; }

    $GDBUS monitor --system --dest org.freedesktop.UDisks2 2>/dev/null \
      | while read -r line; do
        case "$line" in
          *InterfacesAdded*block_devices*)
            path=$(printf '%s' "$line" | ${pkgs.gnugrep}/bin/grep -oE '/org/freedesktop/UDisks2/block_devices/[a-zA-Z0-9_]+' | head -1)
            [ -z "$path" ] && continue
            devname="''${path##*/}"
            # Only act on partitions (sdb1), not whole disks (sdb)
            [[ "$devname" =~ [0-9]$ ]] || continue
            # Settle: udev needs a moment to populate fs properties
            sleep 1
            # Filter to USB only
            tran=$($LSBLK -no TRAN "/dev/$devname" 2>/dev/null | head -1)
            [ "$tran" = "usb" ] || continue

            label=$($LSBLK -no LABEL "/dev/$devname" 2>/dev/null | head -1)
            size=$($LSBLK -no SIZE "/dev/$devname" 2>/dev/null | head -1)
            [ -z "$label" ] && label="(no label)"

            # Actionable notification — clicking "Mount…" launches usb-menu
            ACTION=$($NOTIFY -i drive-removable-media -t 8000 \
              --wait \
              --action="open=Mount…" \
              "USB inserted: $label" "$size — click to manage" || echo "")

            if [ "$ACTION" = "open" ]; then
              "$USB_MENU" &
              disown
            fi
            refresh_waybar
            ;;
          *InterfacesRemoved*block_devices*)
            $NOTIFY -i media-removable -t 3000 "USB removed" ""
            refresh_waybar
            ;;
        esac
      done
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
    power-menu
    usb-menu
    usb-monitor
    # Kept on PATH for interactive shell use. The scripts above call these via
    # absolute /nix/store paths, so removing any of these won't break the scripts —
    # only ad-hoc terminal use of `notify-send`, `lsblk`, `udisksctl`, etc.
    # gnused/gnugrep/gawk/findutils/coreutils/procps are in the NixOS default
    # system path already, so they're omitted here.
    pkgs.hyprsunset
    pkgs.upower
    pkgs.libnotify
    pkgs.iproute2
    pkgs.jq
    pkgs.util-linux
    pkgs.udisks2
    pkgs.glib
  ];

  # Start perf-mode-daemon and bluelight-auto at login
  systemd.user.services.perf-mode-daemon = {
    Unit = { Description = "Battery-aware Hyprland performance daemon"; After = [ "graphical-session.target" ]; };
    Service = { ExecStart = "${perf-mode-daemon}/bin/perf-mode-daemon"; Restart = "on-failure"; };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  systemd.user.services.usb-monitor = {
    Unit = {
      Description = "USB insertion monitor → notifications";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${usb-monitor}/bin/usb-monitor";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
