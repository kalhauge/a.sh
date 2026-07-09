{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) optionals;
in
{
  options = {
    indentation = lib.mkOption {
      type = lib.types.int;
      default = 2;
    };
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "ImportQualifiedPost" ];
    };
  };

  config = {
    command = "fourmolu";
    package = pkgs.fourmolu;
    args = [
      "--stdin-input-file"
      "."
    ]
    ++ optionals (config.indentation != 4) [
      "--indentation"
      "${builtins.toString config.indentation}"
    ]
    ++ lib.concatMap (e: [
      "-o"
      "-X${e}"
    ]) config.extensions;
  };
}
