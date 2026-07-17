{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.languages.bash;
in
{
  options.languages.bash = {
    enable = lib.mkEnableOption "Bash";

    style = {
      simplify = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "simplify the code";
      };
      indent = lib.mkOption {
        type = lib.types.int;
        default = 2;
        example = 0;
        description = "number of spaces to use, 0 for tabs";
      };
    };
  };

  config.formatters."Shell" = lib.mkIf cfg.enable {
    package = pkgs.shfmt;
    args = lib.flatten [
      (lib.optional cfg.style.simplify "-s")
      [
        "-i"
        (builtins.toString cfg.style.indent)
      ]
      "-"
    ];
  };
}
