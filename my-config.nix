{ config, lib, pkgs, modulesPath, ... }:
let
  sources = import ./lon.nix;
  lanzaboote = import sources.lanzaboote {
    inherit pkgs;
  };
  unstable = (import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  }) {
    system = pkgs.stdenv.hostPlatform.system;
    config = config.nixpkgs.config;
  }).extend (_: prev: {
    vimUtils = prev.vimUtils // {
      packDir = packages:
        let addPname = p: if p ? pname then p else p // { pname = p.name; };
        in prev.vimUtils.packDir (builtins.mapAttrs (_: pkg: {
          start = map addPname (pkg.start or []);
          opt = map addPname (pkg.opt or []);
        }) packages);
    };
  });
  gemini-cli_026 = unstable.gemini-cli.overrideAttrs (old: let
    src = old.src.override {
      tag = "v0.27.3";
      hash = "sha256-JUSl5yRJ2YtTCMfPv7oziaZG4yNnsucKlvtjfuzZO+I=";
    };
  in {
    version = "0.27.3";
    inherit src;

    npmDeps = unstable.fetchNpmDeps {
      inherit src;
      hash = "sha256-euy7QwuoJI+07KMUMcRAmmH/zyYgF9wFiLSF4OwQivo=";#lib.fakeHash;
    };
  });
in
{
  imports = [
    lanzaboote.nixosModules.lanzaboote
    <home-manager/nixos>
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit unstable; };
  home-manager.users.${config.myProfile.username} = import ./home.nix;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  programs.nm-applet.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];

    #ipv4 = {
    #  never-default = true;
    #};
  };

  environment.systemPackages = (with pkgs; [
    efibootmgr

    telegram-desktop
    sbctl
    lon
    pavucontrol
    pulseaudio
    slack
    vscode
    nodejs_20
    docker
    docker-compose
    (yarn.override {
      nodejs = nodejs_20;
    })
    thunderbird
    chromium
    zoom-us

    python313
    postgresql.pg_config

    rustc        # The Rust compiler
    cargo        # The Rust package manager
    gcc          # Required for linking Rust binaries

    ffmpeg
    android-tools
    v4l-utils
    ffmpeg pkgs.v4l-utils
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad   # Required for rtmp2src
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav          # Required for avdec_h264

    btop
    mission-center #missioncenter

    intel-gpu-tools #intel_gpu_top

    fastfetch

    ghostty
  ]) ++
  (with unstable; [
    protonvpn-gui
    git
    claude-code
    logseq
  ]) ++
  ([
    #gemini-cli_026
  ]);

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.systemd-boot.configurationLimit = 5;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  services.pipewire.wireplumber.enable = true;
  services.dbus.enable = true;

  hardware.enableAllFirmware = true;

  hardware.firmware = [
    pkgs.sof-firmware
  ];

  boot.kernelParams = [
    "snd-intel-dspcfg.dsp_driver=1"
  ];

  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:win_space_toggle";
  };

  virtualisation.docker.enable = true;

  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  services.ollama = {
    enable = true;
    acceleration = "cuda";
    package = unstable.ollama;
  };

  services.mediamtx = {
    enable = true;
    settings = {
      # Bind only to localhost so external Wi-Fi devices can't access it
      rtspAddress = "127.0.0.1:8554";
      rtmpAddress = "127.0.0.1:1935";

      rtsp = true;
      rtmp = true;
      hls = false;
      webrtc = false;
      paths = {
        all = { };
      };
    };
  };
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="Android Webcam" exclusive_caps=1
    options snd-hda-intel patch=alc289-xps15.fw
  '';

  programs.zsh.enable = true;

  users.users.${config.myProfile.username}.shell = pkgs.zsh;

  programs.nix-ld.enable = true;

  # Starts ssh-agent at login so SSH keys are unlocked once per session.
  # ksshaskpass provides a GUI passphrase prompt; SSH_ASKPASS_REQUIRE=prefer uses it over terminal.
  programs.ssh.startAgent = true;
  programs.ssh.askPassword = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
  environment.sessionVariables.SSH_ASKPASS_REQUIRE = "prefer";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.graphics.enable = true;
  
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = false;
  
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
  
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/nvidia 0700 root root -"
  ];
}
