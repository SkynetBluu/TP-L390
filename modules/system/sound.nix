# modules/system/sound.nix
# Audio — PipeWire (replaces PulseAudio + JACK)

{ config, pkgs, ... }:

{
  # Disable PulseAudio — PipeWire replaces it
  services.pulseaudio.enable = false;

  services.udev.extraRules = ''
    # Expert Sleepers Disting NT — NXP i.MX RT bootloader (SE Blank RT Family)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0135", MODE="0666", TAG+="uaccess"
  '';
  # RTKit — allows PipeWire to get realtime priority
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true; # ALSA compatibility
    alsa.support32Bit = true; # 32-bit app support
    pulse.enable = true; # PulseAudio compatibility layer
    jack.enable = false; # Enable if you need JACK (music production)

    # Low-latency config — good default for a laptop
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 1024;
        default.clock.min-quantum = 32;
        default.clock.max-quantum = 8192;
      };
    };
  };
}
