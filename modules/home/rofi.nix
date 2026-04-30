# modules/home/rofi.nix
# Rofi launcher with Catppuccin Mocha theme

{ config, pkgs, theme, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.alacritty}/bin/alacritty";

    extraConfig = {
      modi            = "drun,run,window";
      show-icons      = true;
      icon-theme      = "Papirus-Dark";
      display-drun    = " Apps";
      display-run     = " Run";
      display-window  = " Windows";
      drun-display-format = "{name}";
      font            = "${theme.fonts.mono} 13";
      lines           = 8;
      columns         = 1;
      fixed-num-lines = true;
      cycle           = true;
    };

    theme = let
      mkLiteral = config: { _type = "literal"; value = config; };
    in {
      "*" = {
        bg        = mkLiteral "${theme.colors.background}";
        bg-alt    = mkLiteral "${theme.colors.backgroundAlt}";
        surface   = mkLiteral "${theme.colors.surface}";
        fg        = mkLiteral "${theme.colors.foreground}";
        fg-dim    = mkLiteral "${theme.colors.foregroundDim}";
        accent    = mkLiteral "${theme.colors.accent}";
        border-c  = mkLiteral "${theme.colors.border}";
        red       = mkLiteral "${theme.colors.red}";

        background-color = mkLiteral "transparent";
        text-color       = mkLiteral "@fg";
        border-color     = mkLiteral "@border-c";
      };

      "window" = {
        background-color = mkLiteral "@bg";
        border           = mkLiteral "2px";
        border-color     = mkLiteral "@accent";
        border-radius    = mkLiteral "10px";
        width            = mkLiteral "480px";
        padding          = mkLiteral "12px";
      };

      "mainbox" = {
        background-color = mkLiteral "transparent";
        spacing          = mkLiteral "8px";
      };

      "inputbar" = {
        background-color = mkLiteral "@bg-alt";
        border-radius    = mkLiteral "6px";
        padding          = mkLiteral "8px 12px";
        spacing          = mkLiteral "8px";
        children         = mkLiteral "[prompt, entry]";
      };

      "prompt" = {
        background-color = mkLiteral "transparent";
        text-color       = mkLiteral "@accent";
        font             = "${theme.fonts.mono} Bold 13";
      };

      "entry" = {
        background-color = mkLiteral "transparent";
        text-color       = mkLiteral "@fg";
        placeholder      = "Search...";
        placeholder-color = mkLiteral "@fg-dim";
      };

      "listview" = {
        background-color = mkLiteral "transparent";
        lines            = mkLiteral "8";
        columns          = mkLiteral "1";
        spacing          = mkLiteral "2px";
        fixed-height     = mkLiteral "true";
      };

      "element" = {
        background-color = mkLiteral "transparent";
        border-radius    = mkLiteral "6px";
        padding          = mkLiteral "8px 12px";
        spacing          = mkLiteral "8px";
        cursor           = mkLiteral "pointer";
      };

      "element normal.normal" = {
        background-color = mkLiteral "transparent";
        text-color       = mkLiteral "@fg-dim";
      };

      "element selected.normal" = {
        background-color = mkLiteral "@surface";
        text-color       = mkLiteral "@fg";
        border-left      = mkLiteral "3px solid";
        border-color     = mkLiteral "@accent";
      };

      "element-icon" = {
        background-color = mkLiteral "transparent";
        size             = mkLiteral "24px";
      };

      "element-text" = {
        background-color = mkLiteral "transparent";
        vertical-align   = mkLiteral "0.5";
      };

      "message" = {
        background-color = mkLiteral "@bg-alt";
        border-radius    = mkLiteral "6px";
        padding          = mkLiteral "8px 12px";
      };

      "textbox" = {
        text-color = mkLiteral "@fg-dim";
      };
    };
  };
}
