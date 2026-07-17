{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.languages.python;
in
{
  options.languages.python = {
    enable = lib.mkEnableOption "Python";
  };

  config.formatters."Python" = lib.mkIf cfg.enable {
    package = pkgs.ruff;
    args = [
      "format"
      "-"
    ];
  };
}
