{
  description = "An empty flake template that you can adapt to your own environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        self,
        config,
        lib,
        flake-parts-lib,
        ...
      }:
      let
        inherit (flake-parts-lib) importApply;
        flakeModules.default = importApply ./nix/flake-module.nix self;
      in
      {
        imports = [
          flakeModules.default
        ];

        flake = {
          inherit flakeModules;
          templates = {
            minimal = {
              path = ./nix/templates/minimal;
              description = "a minimal a.sh setup";
            };
          };
          lib = import ./nix/lib.nix { inherit lib; };
        };

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        perSystem = { config, pkgs, ... }: {
          packages.default = config.packages.ash;
          packages.ash = pkgs.callPackage ./nix/ash { };
          ash = {
            enable = true;
            configuration = {
              languages = {
                nix.enable = true;
                git.enable = true;
                markdown.enable = true;
                bash.enable = true;
              };
            };
          };
        };
      }
    );
}
