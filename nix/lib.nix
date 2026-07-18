{ lib }:
let
  ash-lib = {
    mkAshConfiguration =
      config@{
        pkgs,
        modules,
        system,
      }:
      (lib.evalModules {
        modules = [
          { config._module.args = { inherit pkgs system ash-lib; }; }
          ./ash-module.nix
        ]
        ++ modules;
      }).config.output.json;

  };
in
ash-lib
