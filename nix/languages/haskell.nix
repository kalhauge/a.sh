{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.languages.haskell;
in
{
  options.languages.haskell = {
    enable = lib.mkEnableOption "Haskell";
    style = {
      indent = lib.mkOption {
        type = lib.types.int;
        default = 2;
      };
    };

    formolu = {
      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = lib.flatten [
          (lib.optionals (cfg.style.indent != 4) [
            "--indentation"
            (builtins.toString cfg.style.indent)
          ])
        ];
      };
    };
  };

  config.formatters = lib.mkIf cfg.enable {
    "Haskell" = {
      package = pkgs.writeShellScriptBin "formolu" ''
        exec ${pkgs.fourmolu}/bin/fourmolu \
          --stdin-input-file "$ASH_FILE" \
          ${lib.escapeShellArgs cfg.formolu.args}
      '';
    };
  };
}
