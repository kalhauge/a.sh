{ lib }:
let
  mkSimpleModule =
    mod:
    if builtins.typeOf mod == "set" then
      { ... }:
      {
        config = mod;
      }
    else if builtins.typeOf mod == "file" then
      mkSimpleModule (import mod)
    else
      mod;
  mkAshModule =
    pkgs: extra-config:
    (lib.evalModules {
      modules = [
        { _module.args = { inherit pkgs; }; }
        (mkSimpleModule extra-config)
        ./module.nix
      ];
    });
in
{
  inherit mkAshModule;
  mkAshConfig = pkgs: extra-config: (mkAshModule pkgs extra-config).config.output-json;
  mkAshShell = pkgs: extra-config: (mkAshModule pkgs extra-config).config.output-shell;
  mkAshFormatter = pkgs: extra-config: (mkAshModule pkgs extra-config).config.output-formatter;
  mkAshCheck = pkgs: extra-config: (mkAshModule pkgs extra-config).config.output-check;
}
