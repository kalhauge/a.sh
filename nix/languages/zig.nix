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

  cfg = config.languages.zig;
in
{
  options.languages.zig = {
    enable = mkEnableOption "Zig";

    package = mkOption {
      type = types.package;
      default = pkgs.zig;
      defaultText = "pkgs.zig";
    };

  };

  config = mkIf cfg.enable {
    formatters."Zig" = {
      args = [
        "fmt"
        "--stdin"
      ];
      package = cfg.package;
    };
  };
}
