{
  config,
  options,
  lib,
  ...
}:
{
  options = {
    indent = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "number of spaces to indent, null is tabs";
    };
  };

  config = {
    args =
      (
        if config.indent != null then
          [
            "--indent-type"
            "Spaces"
            "--indent-width"
            (builtins.toString config.indent)
          ]
        else
          [ ]
      )
      ++ [
        "-"
      ];
  };
}
