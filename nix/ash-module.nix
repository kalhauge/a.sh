{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) types mkOption mkEnableOption;
in
{
  options = {
    formatters = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule {
          options = {
            args = mkOption {
              type = types.listOf types.str;
            };
            program = mkOption {
              type = types.str;
            };
          };
        }
      );
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
    formatters = {
      "C" = {
        args = [ "-" ];
        program = "${pkgs.clang-tools}/bin/clang-format";
      };
      "Nix" = {
        args = [ "-" ];
        program = "${pkgs.nixfmt}/bin/nixfmt";
      };
    };

    output = {
      configuration = {
        inherit (config) formatters;
      };
      json = pkgs.writeText "ash.json" (builtins.toJSON config.output.configuration);
    };

  };
}
