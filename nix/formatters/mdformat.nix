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
    wikilink = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "support wikilinks";
    };
    frontmatter = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "support frontmatter";
    };
  };

  config = {
    command = "mdformat";
    package = (
      (pkgs.mdformat.withPlugins (
        ps:
        [ ]
        ++ (if config.wikilink then [ ps.mdformat-wikilink ] else [ ])
        ++ (if config.frontmatter then [ ps.mdformat-frontmatter ] else [ ])
      ))
    );
    args = (if config.number then [ "--number" ] else [ ]) ++ [ "-" ];
  };
}
