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

    verbatims = mkOption {
      description = "extra environments to be considered verbatims";
      type = types.listOf types.str;
      default = [ ];
    };

    lists = mkOption {
      description = "extra environments to be formated like itemize";
      type = types.listOf types.str;
      default = [
        "asparaenum"
        "inparaenum"
      ];
    };
  };

  config = mkIf cfg.enable {
    formatters."TeX" = {
      args = [
        "-s"
        "--config"
        "${(pkgs.formats.toml { }).generate "tex-fmt.toml" {
          inherit (cfg) verbatims lists format-tables;
        }}"
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
