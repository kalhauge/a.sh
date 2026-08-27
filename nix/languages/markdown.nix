{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.languages.markdown;
in
{
  options.languages.markdown = {
    enable = lib.mkEnableOption "Markdown";

    style = {
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

      gfm = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "support GitHub Flavored Markdown";
      };

      beatify.bash = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "format bash in code-blocks";
      };
    };
  };

  config.formatters."Markdown" = lib.mkIf cfg.enable {
    package = (
      (pkgs.mdformat.withPlugins (
        ps:
        lib.flatten [
          (lib.optional cfg.style.wikilink ps.mdformat-wikilink)
          (lib.optional cfg.style.frontmatter ps.mdformat-frontmatter)
          (lib.optional cfg.style.gfm ps.mdformat-gfm)
          (lib.optional cfg.style.beatify.bash ps.mdformat-beautysh)
        ]
      ))
    );
    args = (lib.optional cfg.style.number "--number") ++ [ "-" ];
  };
}
