# modules/home/gtk.nix
# GTK theming — Yaru dark + Bibata cursors

{ config, pkgs, theme, ... }:

{
  gtk = {
    enable = true;

    theme = {
      name    = theme.appearance.gtkTheme;
      package = pkgs.yaru-theme;
    };

    iconTheme = {
      name    = theme.appearance.iconTheme;
      package = pkgs.yaru-theme;
    };

    cursorTheme = {
      name    = theme.appearance.cursorTheme;
      package = pkgs.bibata-cursors;
      size    = theme.appearance.cursorSize;
    };

    font = {
      name = theme.fonts.sans;
      size = theme.fonts.sansSize;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-enable-animations             = true;
      gtk-decoration-layout             = "menu:";
    };

    gtk4 = {
      theme = null; # Yaru GTK4 support is patchy — fall back to system default
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout             = "menu:";
      };
    };
  };

  home.pointerCursor = {
    gtk.enable  = true;
    x11.enable  = true;
    name        = theme.appearance.cursorTheme;
    package     = pkgs.bibata-cursors;
    size        = theme.appearance.cursorSize;
  };

  # GTK3 CSS tweaks
  home.file.".config/gtk-3.0/gtk.css".text = ''
    /* Disable backdrop dimming */
    * { -gtk-icon-effect: none; }
    *:backdrop { opacity: 1.0; }
  '';
}
