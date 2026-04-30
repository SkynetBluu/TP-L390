# modules/home/theme.nix
# Catppuccin Mocha theme — single source of truth for all modules
# Referenced as: let theme = import ./theme.nix; in ...
# Or via config.theme when wired through home.nix extraSpecialArgs

{
  colors = {
    background    = "#1e1e2e";
    backgroundAlt = "#181825";
    surface       = "#313244";
    foreground    = "#cdd6f4";
    foregroundDim = "#bac2de";
    comment       = "#6c7086";
    accent        = "#89b4fa";  # blue
    accentSecondary = "#cba6f7"; # mauve
    border        = "#45475a";
    red           = "#f38ba8";
    green         = "#a6e3a1";
    yellow        = "#f9e2af";
    orange        = "#fab387";
    cyan          = "#94e2d5";
    magenta       = "#f5c2e7";
    blue          = "#89b4fa";
  };

  fonts = {
    mono     = "JetBrainsMono Nerd Font";
    sans     = "Inter";
    monoSize = 12;
    sansSize = 11;
  };

  appearance = {
    gtkTheme    = "Yaru-dark";
    iconTheme   = "Yaru";
    cursorTheme = "Bibata-Modern-Classic";
    cursorSize  = 24;

    nvimColorscheme = "catppuccin";
    nvimFlavor      = "mocha";
  };
}
