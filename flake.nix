{
  description = "Theo's System Config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-wayland = { url = "github:nix-community/nixpkgs-wayland"; };

    nixpkgs-wayland.inputs.master.follows = "master";
  };

  outputs = { nixpkgs, ... }@inputs:
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

          modules = [ ./system/configuration.nix ];
        };
      };
    };
}
