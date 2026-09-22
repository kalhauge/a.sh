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
  options.languages.rust = {
    enable = lib.mkEnableOption "Rust";

    edition = lib.mkOption {
      type = lib.types.str;
      default = "2024";
    };
  };

  config.formatters = lib.mkIf cfg.enable {
    "Rust" = {
      package = pkgs.writeShellScriptBin "rustfmt" ''
        exec ${pkgs.rustfmt}/bin/rustfmt --edition ${cfg.edition}
      '';
    };
  };
}
