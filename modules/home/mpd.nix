# modules/home/mpd.nix
# MPD as a user service — composes naturally with PipeWire's user-session
# socket (no XDG_RUNTIME_DIR dance, no race against systemd-logind).

{ ... }:

{
  services.mpd = {
    enable = true;
    musicDirectory = "/share/slsk/share";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }

      # Save state so playlist/position survives restart
      auto_update "yes"
      restore_paused "yes"
      filesystem_charset "UTF-8"
    '';
    # default network setup is fine: localhost:6600
  };
}
