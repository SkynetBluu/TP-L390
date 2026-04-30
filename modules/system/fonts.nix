# modules/system/fonts.nix
# System-wide fonts — MUST be here (not home.packages) for Wayland/Hyprland

{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  fonts.packages = with pkgs; [
    # Base fonts
    inter                  # Default sans-serif (theme.fonts.sans)
    liberation_ttf         # Arial/Times/Courier replacements
    noto-fonts             # Wide Unicode coverage
    noto-fonts-color-emoji # Emoji
    noto-fonts-cjk-sans    # CJK (Chinese/Japanese/Korean)

    # Icon fonts
    font-awesome           # Icons for Waybar etc.

    # Nerd Fonts — terminals, Waybar, Neovim
    nerd-fonts.jetbrains-mono  # Default monospace (theme.fonts.mono)
    nerd-fonts.caskaydia-cove  # Cascadia Code variant
    nerd-fonts.fira-code
    nerd-fonts.hack
  ];

  fonts.fontconfig = {
    antialias = true;

    defaultFonts = {
      serif     = [ "Noto Serif" "Liberation Serif" ];
      sansSerif = [ "Inter" "Noto Sans" "Liberation Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" "Hack Nerd Font" ];
      emoji     = [ "Noto Color Emoji" ];
    };

    hinting = {
      enable = true;
      style  = "slight";
    };

    subpixel = {
      rgba      = "rgb";
      lcdfilter = "default";
    };
  };
}
