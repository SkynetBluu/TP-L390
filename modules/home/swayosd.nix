# modules/home/swayosd.nix
# SwayOSD — on-screen display for volume and brightness

{ config, pkgs, theme, ... }:

{
  home.packages = [ pkgs.swayosd ];

  systemd.user.services.swayosd = {
    Unit = {
      Description = "SwayOSD - On-screen display for volume/brightness";
      PartOf       = [ "graphical-session.target" ];
      After        = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart  = "${pkgs.swayosd}/bin/swayosd-server";
      Restart    = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  xdg.configFile."swayosd/config.toml".text = ''
    [server]
    show_percentage = true
    max_volume = 100
  '';

  xdg.configFile."swayosd/style.css".text = ''
    window {
      background: ${theme.colors.backgroundAlt};
      border-radius: 8px;
      border: 1px solid ${theme.colors.surface};
      padding: 14px;
    }
    #container { margin: 6px; }
    progressbar {
      min-height: 6px;
      border-radius: 3px;
      background: transparent;
    }
    trough {
      min-height: 6px;
      border-radius: 3px;
      background: ${theme.colors.surface};
    }
    progress {
      min-height: 6px;
      border-radius: 3px;
      background: ${theme.colors.accent};
    }
    label {
      font-family: "${theme.fonts.mono}";
      font-size: 12px;
      color: ${theme.colors.foreground};
      margin: 4px;
    }
    image { color: ${theme.colors.foreground}; }
  '';
}
