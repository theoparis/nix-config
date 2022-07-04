{
  description = "Theo's System Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-wayland = { url = "github:nix-community/nixpkgs-wayland"; };
    nixpkgs-wayland.inputs.master.follows = "master";
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        theo-pc = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };

          modules = [
            ./system/configuration.nix
            hyprland.nixosModules.default
            { programs.hyprland.enable = true; }
          ];
        };
      };
    };
}
