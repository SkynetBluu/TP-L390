# modules/system/sound.nix
# Audio — PipeWire (replaces PulseAudio + JACK)

{ pkgs, ... }:

{
  # Disable PulseAudio — PipeWire replaces it
  services.pulseaudio.enable = false;

  services.udev.extraRules = ''
    # Expert Sleepers Disting NT — normal MIDI mode
    SUBSYSTEM=="usb", ATTR{idVendor}=="3773", ATTR{idProduct}=="0001", MODE="0666", TAG+="uaccess"

    # Disting NT — NXP ROM bootloader (SDP mode)
    SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ATTR{idProduct}=="0135", MODE="0666", TAG+="uaccess"

    # Disting NT — NXP flashloader (during firmware flash)
    SUBSYSTEM=="usb", ATTR{idVendor}=="15a2", ATTR{idProduct}=="0073", MODE="0666", TAG+="uaccess"
  '';
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "99-disting-nt-rules";
      destination = "/etc/udev/rules.d/99-disting-nt.rules";
      text = ''
        # nt_helper presence check satisfier.
        # Actual active rules are in services.udev.extraRules.
        SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ATTR{idProduct}=="0135", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="15a2", ATTR{idProduct}=="0073", MODE="0666"
      '';
    })
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libusb1
      systemd
      zlib
      stdenv.cc.cc.lib
    ];
  };

  # RTKit — allows PipeWire to get realtime priority
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true; # ALSA compatibility
    alsa.support32Bit = true; # 32-bit app support
    pulse.enable = true; # PulseAudio compatibility layer
    jack.enable = false; # Enable if you need JACK (music production)

    # Comfortable laptop default. The 1024 quantum is NOT low-latency
    # (real low-latency starts around 256). Apps that actually need lower
    # latency can request down to min-quantum=32 on a per-stream basis.
    extraConfig.pipewire."92-laptop-defaults" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 1024;
        default.clock.min-quantum = 32;
        default.clock.max-quantum = 8192;
      };
    };
  };
}
