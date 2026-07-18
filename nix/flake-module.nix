localFlake:
top@{
  self,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption mkEnableOption;
in
{
  imports = [
    (flake-parts-lib.mkTransposedPerSystemModule {
      name = "ashConfiguration";
      file = ./flake-module.nix;
      option = lib.mkOption {
        type = types.package;
        description = ''
          The Ash configuration.
        '';
      };
    })
  ];

  options = {

    flake.ashModules = mkOption {
      type = types.lazyAttrsOf types.deferredModule;
      default = { };
      description = ''
        Ash modules.
      '';
    };
  };

  config.perSystem =
    {
      config,
      pkgs,
      self',
      lib,
      system,
      ...
    }:
    {
      options = {
        ash = {
          enable = mkEnableOption "enable ash";

          package = mkOption {
            type = types.package;
            default = localFlake.packages.${system}.ash;
          };

          configuration = mkOption {
            default = { };
            type = types.deferredModule;
          };
        };
      };

      config = lib.mkIf config.ash.enable {
        ashConfiguration = localFlake.lib.mkAshConfiguration {
          inherit pkgs system;
          modules = [
            config.ash.configuration
          ];
        };

        formatter = pkgs.writeShellScriptBin "format.sh" ''
          FILE="$PRJ_ROOT/.config/ash.json"

          if ! grep -qxF ".config/ash.json" "$PRJ_ROOT/.gitignore"; then
            echo ".config/ash.json" >> "$PRJ_ROOT/.gitignore" 
            git rm --cached -f --ignore-unmatch "$FILE"
          fi

          nix-store --add-root "$FILE" --realise ${config.ashConfiguration}
          git ls-files . | ${lib.getExe config.ash.package} fmt $@
        '';

        # checks.ash-check = ashModule.config.output-check { src = self; };
      };
    };
}
