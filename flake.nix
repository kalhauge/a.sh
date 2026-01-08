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
        inputs.nixpkgs.lib.genAttrs systems (
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

        mkAshShell =
          pkgs: extra-config:
          (mkAshModule (
            {
              _module.args = { inherit pkgs; };
            }
            // extra-config
          )).config.output-shell;

        mkFormatterForEachSystem =
          {
            systems ? supportedSystems,
            configPerSystem ? system: "packages.${system}.ash-config",
          }:
          inputs.nixpkgs.lib.genAttrs systems (
            system:
            self.lib.mkFormatter {
              inherit system;
              configPath = configPerSystem system;
            }
          );

        mkFormatter =
          {
            system,
            pkgs ? inputs.nixpkgs.legacyPackages.${system},
            lib ? inputs.nixpkgs.lib,
            configPath ? "packages.${system}.ash-config",
          }:
          pkgs.writeShellScriptBin "format.sh" ''
            nix build .#${configPath} --out-link ash.json
            git ls-files | ${lib.getExe self.packages.${system}.default} fmt $@
          '';

        mkFormatCheck =
          let
            self' = self;
          in
          {
            system,
            self,
            src ? self,
            pkgs ? inputs.nixpkgs.legacyPackages.${system},
            lib ? inputs.nixpkgs.lib,
            config ? self.packages.${system}.ash-config,
            formatAll ? false,
          }:
          pkgs.runCommand "check"
            {
              inherit src;
              buildInputs = [ self'.packages.${system}.ash ];
              ASH_SINGLETON_CONFIG = config;
            }
            ''
              set -eu
              cd $src
              find . -type f | a.sh fmt -D
              touch "$out"
            '';
      };

      packages = forEachSystem {
        do =
          { pkgs, self', ... }:
          {
            default = self'.packages.ash;

            ash = self.lib.mkAshShell pkgs {
              enableAllLanguages = true;
            };

            ash-full = self.lib.mkAshShell pkgs {
              emitPaths = true;
              enableAllLanguages = true;
            };

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

      formatter = self.lib.mkFormatterForEachSystem {
        systems = supportedSystems;
      };

      checks = forEachSystem {
        do =
          {
            self',
            pkgs,
            system,
            ...
          }:
          {
            ash = self'.packages.ash;
            ash-full = self'.packages.ash-full;
            formatcheck = self.lib.mkFormatCheck { inherit system self; };
          };
      };
    };
}
