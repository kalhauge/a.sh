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
        withSystem,
        moduleWithSystem,
        ...
      }:
      {
        imports = [
        ];
        flake = {
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
                systems,
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
              withSystem system (
                { config, ... }:
                pkgs.writeShellScriptBin "format.sh" ''
                  FILE="$PRJ_ROOT/.config/ash.json"

                  grep -qxF ".config/ash.json" "$PRJ_ROOT/.gitignore" || 
                    echo ".config/ash.json" >> "$PRJ_ROOT/.gitignore" && 
                    git rm --cached -f --ignore-unmatch "$FILE"

                  nix build .#${configPath} --out-link "$FILE"
                  git ls-files . | ${lib.getExe config.packages.default} fmt $@
                ''
              );

            mkFormatCheck =
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
                  buildInputs = [ self.packages.${system}.ash ];
                  ASH_SINGLETON_CONFIG = config;
                }
                ''
                  set -eu
                  cd $src
                  find . -type f | a.sh fmt -D
                  touch "$out"
                '';
          };
          templates = {
            minimal = {
              path = ./nix/templates/minimal;
              description = "a minimal a.sh setup";
            };
          };
        };
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
            packages = {
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
                  "TSV"
                ];
              };
            };
            formatter = self.lib.mkFormatter {
              inherit system;
            };

            checks = {
              ash = self'.packages.ash;
              ash-full = self'.packages.ash-full;
              formatcheck = self.lib.mkFormatCheck { inherit system self; };
            };
          };
      }
    );
}
