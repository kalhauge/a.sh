localFlake: { self, ... }: {
  perSystem =
    {
      config,
      pkgs,
      self',
      lib,
      system,
      ...
    }:

    let
      ashModule = (localFlake.lib.mkAshModule pkgs config.ash.config);
    in
    {
      options = {
        ash = {
          enable = lib.mkEnableOption "enable a.sh";

          config = lib.mkOption {
            # type = lib.types.submodule ./module.nix;
          };
        };
      };

      config =
        let
          cfg = config.ash;
        in
        lib.mkIf cfg.enable {
          formatter = ashModule.config.output-formatter;
          checks.ash-check = ashModule.config.output-check { src = self; };
        };
    };
}
