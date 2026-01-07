{
  description = "An empty flake template that you can adapt to your own environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "aarch64-darwin" # 64-bit ARM macOS
        "x86_64-darwin" # 64-bit Intel/AMD Linux
      ];

      forEachSystem =
        {
          systems ? supportedSystems,
          do,
        }:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          do {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
            };
            lib = inputs.nixpkgs.lib;
            self' = inputs.nixpkgs.lib.mapAttrs (k: v: v.${system}) self;
          }
        );
    in
    {
      lib = rec {
        mkSimpleModule =
          mod:
          if builtins.typeOf mod == "set" then
            { ... }:
            {
              config = mod;
            }
          else if builtins.typeOf mod == "file" then
            mkSimpleModule (import mod)
          else
            mod;
        mkAshModule =
          extra-config:
          (inputs.nixpkgs.lib.evalModules {
            modules = [
              (mkSimpleModule extra-config)
              ./nix/module.nix
            ];
          });
        mkAshConfig =
          pkgs: extra-config:
          (mkAshModule (
            {
              _module.args = { inherit pkgs; };
            }
            // extra-config
          )).config.output-json;

        mkFormatter =
          {
            system,
            pkgs ? inputs.nixpkgs.legacyPackages.${system},
            lib ? inputs.nixpkgs.lib,
            configPath ? "packages.${system}.ash-config",
            formatAll ? false,
          }:
          pkgs.writeShellScriptBin "format.sh" (
            ''
              nix build .#${configPath} --out-link ash.json
            ''
            + lib.optionalString formatAll ''
              git ls-files | ${lib.getExe self.packages.${system}.default} -d fmt -w
            ''
          );
      };

      packages = forEachSystem {
        do =
          { pkgs, ... }:
          {
            default = pkgs.callPackage ./nix { };
            ash-config = self.lib.mkAshConfig pkgs {
              emitPaths = true;
              usedLanguages = [
                "Git Attributes"
                "Nix"
                "Shell"
                "Ignore List"
                "JSON"
                "Markdown"
              ];
            };
          };
      };
      formatter = forEachSystem {
        do =
          { system, ... }:
          self.lib.mkFormatter {
            inherit system;
            formatAll = true;
          };
      };

      checks = forEachSystem {
        do =
          {
            self',
            pkgs,
            ...
          }:
          {
            ash = self'.packages.default;
          };
      };
    };
}
