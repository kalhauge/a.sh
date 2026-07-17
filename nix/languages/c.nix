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

  cfg = config.languages.c;
in
{
  options.languages.c = {
    enable = mkEnableOption "C";
  };

  config = mkIf cfg.enable {
    formatters."C" = {
      args = [ "-" ];
      program = "${pkgs.clang-tools}/bin/clang-format";
    };
  };
}
