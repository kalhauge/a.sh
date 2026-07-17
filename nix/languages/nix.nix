{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    languages.nix.enable = lib.mkEnableOption "Nix";
  };

  config = {
    formatters."Nix" = lib.mkIf config.languages.nix.enable {
      package = pkgs.nixfmt;
      args = [ "-" ];
    };
  };
}
