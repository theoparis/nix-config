{ config, pkgs, inputs, writeScript, lib, stdenv, ... }:

let
  change-mac = pkgs.writeShellScript "change-mac" ''
    card=$1
    tmp=$(mktemp)
    ${pkgs.macchanger}/bin/macchanger "$card" -s | grep -oP "[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[^ ]*" > "$tmp"
    mac1=$(cat "$tmp" | head -n 1)
    mac2=$(cat "$tmp" | tail -n 1)
    if [ "$mac1" = "$mac2" ]; then
      if [ "$(cat /sys/class/net/"$card"/operstate)" = "up" ]; then
        ${pkgs.iproute2}/bin/ip link set "$card" down &&
        ${pkgs.macchanger}/bin/macchanger -r "$card"
        ${pkgs.iproute2}/bin/ip link set "$card" up
      else
        ${pkgs.macchanger}/bin/macchanger -r "$card"
      fi
    fi
  '';
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
    binaryCaches =
      [ "https://cache.nixos.org" "https://nixpkgs-wayland.cachix.org" ];
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;

  boot.supportedFilesystems = [ "zfs" ];

  networking.hostName = "theo-pc";
  networking.hostId = "db48aa7f";
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;

  systemd.services.macchanger = {
    enable = true;
    description = "macchanger on wlan0";
    wants = [ "network-pre.target" ];
    before = [ "network-pre.target" ];
    bindsTo = [ "sys-subsystem-net-devices-wlan0.device" ];
    after = [ "sys-subsystem-net-devices-wlan0.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${change-mac} wlan0";
    };
  };

  time.timeZone = "America/Los_Angeles";

  sound.enable = true;

  users.users.theo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.nushell;
  };

  environment.systemPackages = with pkgs; [
    inputs.nixpkgs-wayland.packages.${system}.waybar
    inputs.nixpkgs-wayland.packages.${system}.grim
    inputs.nixpkgs-wayland.packages.${system}.slurp
    inputs.nixpkgs-wayland.packages.${system}.swaybg
    inputs.nixpkgs-wayland.packages.${system}.wl-clipboard
    inputs.nixpkgs-wayland.packages.${system}.wofi
    inputs.nixpkgs-wayland.packages.${system}.xdg-desktop-portal-wlr
    inputs.nixpkgs-wayland.packages.${system}.wlr-randr
    inputs.nixpkgs-wayland.packages.${system}.wlroots
    inputs.nixpkgs-wayland.packages.${system}.obs-wlrobs
    stow
    git
    delta
    macchanger
    zig
    river
    kitty
    gnome.nautilus
    neovim
    curl
    ripgrep
    skim
    tealdeer
    hyperfine
    helix
    nixfmt
    rnix-lsp
    tmux
    llvmPackages_13.clang
    llvmPackages_13.llvm
    lldb
    lld_13
    rustup
    kmon
    bat
    fd
    sd
    bottom
    xh
    ffmpeg
    xplr
    glow
    lm_sensors
    btrfs-progs
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh.enable = true;
  services.dbus.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  xdg.portal.wlr.enable = true;

  system.stateVersion = "22.05";
}

