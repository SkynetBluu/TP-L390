# modules/home/waybar.nix
# Waybar configuration for ThinkPad L390
# Catppuccin Mocha theme

{ config, pkgs, theme, ... }:

{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };

    settings = {
      mainBar = {
        layer    = "top";
        position = "top";
        height   = 34;
        spacing  = 2;

        modules-left   = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right  = [
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "pulseaudio"
          "network"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format           = "{name}";
          sort-by-number   = true;
          on-click         = "activate";
          all-outputs      = true;
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };

        "hyprland/window" = {
          max-length       = 60;
          separate-outputs = true;
          rewrite = {
            "(.*) - Brave" = "$1";
            "(.*) - Alacritty" = "$1";
          };
        };

        clock = {
          format     = " {:%H:%M}";
          format-alt = " {:%A %d %B %Y — %H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            on-scroll = 1;
          };
        };

        cpu = {
          format   = "󰻠 {usage}%";
          interval = 5;
          tooltip  = true;
          on-click = "alacritty -e btop";
        };

        memory = {
          format   = "󰍛 {percentage}%";
          interval = 10;
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB";
          on-click = "alacritty -e btop";
        };

        temperature = {
          hwmon-path = "/sys/class/hwmon/hwmon6/temp1_input";
          critical-threshold = 85;
          format       = " {temperatureC}°C";
          tooltip      = true;
        };

        backlight = {
          device   = "intel_backlight";
          format   = "{icon} {percent}%";
          format-icons = [ "󰃞" "󰃟" "󰃠" ];
          on-scroll-up   = "brightnessctl set +5%";
          on-scroll-down = "brightnessctl set 5%-";
        };

        pulseaudio = {
          format        = "{icon} {volume}%";
          format-muted  = "󰝟 muted";
          format-icons  = {
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click       = "pavucontrol";
          on-scroll-up   = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        network = {
          format-wifi       = "󰤨 {signalStrength}%";
          format-ethernet   = "󰈀 {bandwidthDownBytes}";
          format-disconnected = "󰤭";
          tooltip-format-wifi = "󰤨 {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-ethernet = "󰈀 {ifname}\nIP: {ipaddr}";
          on-click = "alacritty -e nmtui";
          interval = 10;
        };

        battery = {
          states = {
            warning  = 30;
            critical = 15;
          };
          format          = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged  = "󰚥 {capacity}%";
          format-icons    = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          tooltip-format  = "{timeTo}\nPower: {power:.1f}W";
          on-click        = "battery-mode";
        };

        tray = {
          spacing   = 8;
          icon-size = 16;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: alpha(${theme.colors.background}, 0.92);
        color: ${theme.colors.foreground};
        border-bottom: 2px solid ${theme.colors.surface};
      }

      /* Workspaces */
      #workspaces button {
        padding: 0 8px;
        color: ${theme.colors.comment};
        background: transparent;
        border-bottom: 2px solid transparent;
      }

      #workspaces button.active {
        color: ${theme.colors.accent};
        border-bottom: 2px solid ${theme.colors.accent};
        background: alpha(${theme.colors.accent}, 0.1);
      }

      #workspaces button.urgent {
        color: ${theme.colors.red};
        border-bottom: 2px solid ${theme.colors.red};
      }

      #workspaces button:hover {
        color: ${theme.colors.foreground};
        background: alpha(${theme.colors.foreground}, 0.06);
      }

      /* Window title */
      #window {
        color: ${theme.colors.comment};
        font-size: 12px;
        padding: 0 8px;
      }

      /* Clock */
      #clock {
        color: ${theme.colors.foreground};
        font-weight: bold;
        padding: 0 12px;
      }

      /* All right modules */
      #cpu, #memory, #temperature, #backlight,
      #pulseaudio, #network, #battery, #tray {
        padding: 0 8px;
        color: ${theme.colors.foregroundDim};
      }

      /* Hover */
      #cpu:hover, #memory:hover, #temperature:hover,
      #backlight:hover, #pulseaudio:hover, #network:hover,
      #battery:hover {
        color: ${theme.colors.foreground};
        background: alpha(${theme.colors.foreground}, 0.06);
        border-radius: 4px;
      }

      /* States */
      #battery.charging { color: ${theme.colors.green}; }
      #battery.warning:not(.charging) { color: ${theme.colors.orange}; }
      #battery.critical:not(.charging) {
        color: ${theme.colors.red};
        animation: blink 1s linear infinite;
      }

      #temperature.critical { color: ${theme.colors.red}; }

      #pulseaudio.muted { color: ${theme.colors.comment}; opacity: 0.5; }

      #network.disconnected { color: ${theme.colors.red}; }

      @keyframes blink {
        to { color: ${theme.colors.foreground}; }
      }

      /* Tray */
      #tray > .passive { -gtk-icon-effect: dim; }
      #tray > .needs-attention { -gtk-icon-effect: highlight; }
    '';
  };
}
