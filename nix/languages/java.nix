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

  cfg = config.languages.java;
in
{
  options.languages.java = {
    enable = mkEnableOption "Java";
  };

  config = mkIf cfg.enable {
    formatters."Java" = {
      args = [
        "--assume-filename"
        "$ASH_FILE"
        "-"
      ];
      program = "${pkgs.google-java-format}/bin/google-java-format";
    };
  };
}
