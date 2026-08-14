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
  };

  config = mkIf cfg.enable {
    formatters."TeX" = {
      args = [
        "-s"
      ]
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
