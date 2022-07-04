{ config, pkgs, inputs, ... }:

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
  # Use the systemd-boot EFI boot loader.
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
    description = "macchanger on wlo1";
    wants = [ "network-pre.target" ];
    before = [ "network-pre.target" ];
    bindsTo = [ "sys-subsystem-net-devices-wlo1.device" ];
    after = [ "sys-subsystem-net-devices-wlo1.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${change-mac} wlo1";
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
    git
    delta
    macchanger
    zig
    river
    alacritty
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
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}

