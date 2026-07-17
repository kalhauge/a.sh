{ lib }:
let
  ash-lib = {
    mkAshConfiguration =
      config@{ pkgs, modules }:
      (lib.evalModules {
        modules = [
          { config._module.args = { inherit pkgs ash-lib; }; }
          ./ash-module.nix
        ]
        ++ modules;
      }).config.output.json;

  };
in
ash-lib
