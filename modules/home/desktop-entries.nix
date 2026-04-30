# modules/home/desktop-entries.nix
# XDG desktop entries + launcher scripts

{ pkgs, ... }:

let
  nvim-launcher = pkgs.writeShellScriptBin "nvim-launcher" ''
    if [ -n "$1" ]; then
      exec alacritty -e nvim "$@"
    else
      exec alacritty -e nvim
    fi
  '';
in
{
  home.packages = [
    nvim-launcher
    pkgs.popsicle   # USB flasher
    pkgs.parted
    pkgs.gparted
    pkgs.ntfs3g
    pkgs.exfatprogs
  ];

  xdg.desktopEntries = {
    # Brave — explicit .desktop needed since Firejail wrapper doesn't
    # propagate the upstream brave-browser.desktop to XDG search paths
    brave-browser = {
      name        = "Brave Web Browser";
      genericName = "Web Browser";
      comment     = "Access the Internet";
      exec        = "brave %U";
      icon        = "brave-browser";
      terminal    = false;
      type        = "Application";
      categories  = [ "Network" "WebBrowser" ];
      mimeType    = [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ];
      actions = {
        "new-window"         = { name = "New Window"; exec = "brave"; };
        "new-private-window" = { name = "New Private Window"; exec = "brave --incognito"; };
      };
    };

    # Neovim with Alacritty launcher
    nvim = {
      name        = "Neovim";
      genericName = "Text Editor";
      comment     = "Edit text files";
      exec        = "nvim-launcher %F";
      icon        = "nvim";
      terminal    = false;
      type        = "Application";
      categories  = [ "Utility" "TextEditor" ];
      mimeType    = [
        "text/plain"
        "text/english"
        "application/x-shellscript"
        "text/x-c" "text/x-c++"
        "text/x-java" "text/x-python"
      ];
    };

    # Popsicle — USB flasher
    popsicle = {
      name        = "Popsicle";
      genericName = "USB Flasher";
      comment     = "Flash multiple USB drives in parallel";
      exec        = "${pkgs.popsicle}/bin/popsicle-gtk";
      icon        = "usb-creator";
      terminal    = false;
      type        = "Application";
      categories  = [ "System" "Utility" ];
    };
  };
}
