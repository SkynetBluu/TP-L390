# modules/system/locale.nix
# Locale, timezone, keyboard

{ config, pkgs, ... }:

{
  # Locale
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS        = "en_GB.UTF-8";
      LC_IDENTIFICATION = "en_GB.UTF-8";
      LC_MEASUREMENT    = "en_GB.UTF-8";
      LC_MONETARY       = "en_GB.UTF-8";
      LC_NAME           = "en_GB.UTF-8";
      LC_NUMERIC        = "en_GB.UTF-8";
      LC_PAPER          = "en_GB.UTF-8";
      LC_TELEPHONE      = "en_GB.UTF-8";
      LC_TIME           = "en_GB.UTF-8";
    };
  };

  # Keyboard layout
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Console keyboard
  console.keyMap = "uk";
}
