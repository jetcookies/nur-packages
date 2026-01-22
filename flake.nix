{
  description = "My personal NUR repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: rec {
        legacyPackages = import ./default.nix { inherit pkgs; };
        packages = nixpkgs.lib.filterAttrs (_: nixpkgs.lib.isDerivation) legacyPackages;
      };
      flake = {
        nixosModules = {
          subconverter = import ./modules/services/networking/subconverter.nix;
        };
      };
    };
}
