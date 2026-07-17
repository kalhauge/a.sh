{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.languages.lua;
in
{
  options.languages.lua = {
    enable = lib.mkEnableOption "Lua";

    style = {
      indent = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "number of spaces to indent, 0 is tabs";
      };
    };
  };

  config.formatters."Lua" = lib.mkIf cfg.enable {
    package = pkgs.stylua;
    args = lib.flatten [
      (lib.optionals (cfg.indent != 0) [
        "--indent-type"
        "Spaces"
        "--indent-width"
        (builtins.toString cfg.indent)
      ])
      "-"
    ];
  };
}
