# modules/home/desktop-entries.nix
# XDG desktop entries + launcher scripts

{ pkgs, ... }:

let
  nvim-launcher = pkgs.writeShellScriptBin "nvim-launcher" ''
    if [ -n "$1" ]; then
      exec ghostty -e nvim "$@"
    else
      exec ghostty -e nvim
    fi
  '';

  hx-launcher = pkgs.writeShellScriptBin "hx-launcher" ''
    if [ -n "$1" ]; then
      exec ghostty -e hx "$@"
    else
      exec ghostty -e hx
    fi
  '';
in
{
  home.packages = [
    nvim-launcher
    hx-launcher
    pkgs.popsicle # USB flasher — paired with the .desktop entry below
    # parted/gparted/ntfs3g/exfatprogs live in environment.systemPackages
    # (configuration.nix) so they're usable from a TTY / recovery shell
  ];

  xdg.desktopEntries = {
    # Brave — explicit .desktop needed since Firejail wrapper doesn't
    # propagate the upstream brave-browser.desktop to XDG search paths
    brave-browser = {
      name = "Brave Web Browser";
      genericName = "Web Browser";
      comment = "Access the Internet";
      exec = "brave %U";
      icon = "brave-browser";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ];
      actions = {
        "new-window" = { name = "New Window"; exec = "brave"; };
        "new-private-window" = { name = "New Private Window"; exec = "brave --incognito"; };
      };
    };

    # Neovim with Ghostty launcher
    nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      comment = "Edit text files";
      exec = "nvim-launcher %F";
      icon = "nvim";
      terminal = false;
      type = "Application";
      categories = [ "Utility" "TextEditor" ];
      mimeType = [
        "text/plain"
        "text/english"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
        "text/x-java"
        "text/x-python"
      ];
    };

    # Helix with Ghostty launcher — system default editor
    helix = {
      name = "Helix";
      genericName = "Text Editor";
      comment = "Edit text files";
      exec = "hx-launcher %F";
      icon = "text-editor";
      terminal = false;
      type = "Application";
      categories = [ "Utility" "TextEditor" ];
      mimeType = [
        "text/plain"
        "text/english"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
        "text/x-java"
        "text/x-python"
      ];
    };

    # Popsicle — USB flasher
    popsicle = {
      name = "Popsicle";
      genericName = "USB Flasher";
      comment = "Flash multiple USB drives in parallel";
      exec = "${pkgs.popsicle}/bin/popsicle-gtk";
      icon = "usb-creator";
      terminal = false;
      type = "Application";
      categories = [ "System" "Utility" ];
    };

    yazi-ghostty = {
      name = "Yazi (Ghostty)";
      exec = "ghostty -e yazi %U";
      terminal = false;
      mimeType = [ "inode/directory" ];
      categories = [ "System" "FileManager" ];
    };
  };
}
