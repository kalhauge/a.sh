{ lib }:
let
  mkAshConfiguration =
    config@{ pkgs, modules }:
    (lib.evalModules {
      modules = [
        { config._module.args = { inherit pkgs; }; }
        ./ash-module.nix
      ]
      ++ modules;
    }).config.output.json;

in
{
  inherit mkAshConfiguration;
}
