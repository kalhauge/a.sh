{
  config,
  pkgs,
  lib,
  mdformat,
  ...
}:
{
  options = {
    number = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "make numbers increment in ordered lists";
    };
    wikilinks = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "support wikilinks";
    };
  };

  config = {
    command = "mdformat";
    package = (
      if config.wikilinks then
        (pkgs.mdformat.withPlugins (ps: [
          ps.mdformat-wikilink
        ]))
      else
        pkgs.mdformat
    );
    args = (if config.number then [ "--number" ] else [ ]) ++ [ "-" ];
  };
}
