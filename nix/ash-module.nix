{
  lib,
  pkgs,
  config,
  ...
}:
let

  inherit (lib) types mkOption mkEnableOption;

  formatterModule =
    {
      pkgs,
      config,
      name,
      ...
    }:
    {
      options = {
        args = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        program = mkOption {
          type = types.path;
          default = lib.getExe config.package;
          defaultText = "lib.getExe config.package";
        };
        package = mkOption {
          type = types.package;
        };
        command = mkOption {
          type = types.listOf types.str;
          default = if config.skip then [ ] else [ (builtins.toString config.program) ] ++ config.args;
          defaultText = "[config.program] ++ config.args";
        };
        skip = mkOption {
          type = types.bool;
          default = false;
        };
      };
    };

in
{
  imports = [
    ./languages/default.nix
  ];

  options = {

    formatters = mkOption {
      default = { };
      type = types.attrsOf (types.submodule formatterModule);
    };

    output = {
      configuration = mkOption {
        readOnly = true;
      };
      json = mkOption {
        readOnly = true;
        type = types.package;
      };
    };
  };

  config = {
    output = {
      configuration = {
        formatters = lib.mapAttrs (k: v: v.command) config.formatters;
      };
      json = pkgs.writeText "ash.json" (builtins.toJSON config.output.configuration);
    };
  };
}
