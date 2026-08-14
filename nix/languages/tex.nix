{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    ;

  cfg = config.languages.tex;
in
{
  options.languages.tex = {
    enable = mkEnableOption "LaTeX+";

    wrap = mkOption {
      description = "wrap long lines";
      type = types.int;
      default = 0;
    };

    format-tables = mkOption {
      description = "format tables";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    formatters."TeX" = {
      args = [
        "-s"
      ]
      ++ lib.optional cfg.format-tables "--format-tables"
      ++ (
        if cfg.wrap == 0 then
          [ "--nowrap" ]
        else
          [
            "--wraplen"
            "${cfg.wrap}"
          ]
      );
      program = "${lib.getExe pkgs.tex-fmt}";
    };
  };
}
