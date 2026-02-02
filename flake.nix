{
  description = "My personal NUR repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = [ "x86_64-linux" ];
        perSystem = { config, self', inputs', pkgs, system, ... }: rec {
          legacyPackages = import ./default.nix { inherit pkgs; };
          packages = lib.filterAttrs (_: lib.isDerivation) legacyPackages;
        };
        flake = {
          nixosModules = {
            subconverter = import ./modules/services/networking/subconverter.nix;
          };
        };
      }
    );

  nixConfig = {
    extra-substituters = [
      "https://jetcookies.cachix.org"
    ];
    extra-trusted-public-keys = [
      "jetcookies.cachix.org-1:YM4ERAadhoioRkDA5ZKgnKN98N5x0ubV8t6HeIekcnc="
    ];
  };
}
