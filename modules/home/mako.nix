# modules/home/mako.nix
# Mako notification daemon

{ config, theme, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      background-color  = theme.colors.backgroundAlt;
      text-color        = theme.colors.foreground;
      border-color      = theme.colors.accent;
      progress-color    = "over ${theme.colors.surface}";
      border-radius     = 6;
      border-size       = 2;
      width             = 360;
      height            = 150;
      max-visible       = 3;
      margin            = "8";
      padding           = "14";
      default-timeout   = 4000;
      ignore-timeout    = false;
      font              = "${theme.fonts.mono} 10";
      icons             = true;
      max-icon-size     = 32;
      icon-location     = "left";
      actions           = true;
      group-by          = "app-name";
      format            = "<b>%s</b>\\n%b";
      layer             = "overlay";
      anchor            = "top-right";

      "urgency=low" = {
        default-timeout = 2000;
        border-color    = theme.colors.border;
      };

      "urgency=high" = {
        border-color    = theme.colors.red;
        default-timeout = 0;
      };

      "app-name=SwayOSD" = {
        default-timeout = 1000;
        group-by        = "app-name";
      };
    };
  };
}
