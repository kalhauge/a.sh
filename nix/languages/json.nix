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
  options.languages.json = {
    enable = mkEnableOption "JSON";
  };

  config = mkIf cfg.enable {
    formatters."JSON" = {
      args = [ "." ];
      program = "${pkgs.jq}/bin/jq";
    };
  };
}
