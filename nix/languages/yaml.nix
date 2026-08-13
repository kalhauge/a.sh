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

  cfg = config.languages.yaml;
in
{
  options.languages.yaml = {
    enable = mkEnableOption "YAML";
  };

  config = mkIf cfg.enable {
    formatters."YAML" = {
      args = [ "-in" ];
      program = "${pkgs.yamlfmt}/bin/yamlfmt";
    };
  };
}
