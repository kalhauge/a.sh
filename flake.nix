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

        debug = true;

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        perSystem =
          {
            config,
            pkgs,
            self',
            system,
            ...
          }:
          {
            ash = {
              enable = true;
              config = {
                emitPaths = true;
                usedLanguages = [
                  "Git Attributes"
                  "Nix"
                  "Shell"
                  "Ignore List"
                  "JSON"
                  "Markdown"
                  "TSV"
                ];

              };
            };

            packages = {
              default = self'.packages.ash;

              ash = self.lib.mkAshShell pkgs {
                enableAllLanguages = true;
              };

              ash-full = self.lib.mkAshShell pkgs {
                emitPaths = true;
                enableAllLanguages = true;
              };
            };

            checks = {
              ash = self'.packages.ash;
              ash-full = self'.packages.ash-full;
            };
          };
      }
    );
}
