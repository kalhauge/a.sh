{
  lib,
  pkgs,
  config,
  options,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkIf
    mkEnableOption
    mkPackageOption
    ;

  mkFormatter =
    name:
    mkOption {
      default = { };
      description = "Configuration for formatter ${name}";
      type = types.submodule (
        { config, ... }:
        {
          imports = [
            (
              let
                m = import ./formatters/${name}.nix;
              in
              if builtins.typeOf m == "set" then { config = m; } else m
            )
          ];

          config._module.args = { inherit pkgs name; };

          options = {
            enable = mkEnableOption name;
            command = mkOption {
              type = types.str;
              default = name;
            };
            args = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };
            nixpkgsPackage = mkOption {
              type = types.str;
              default = name;
            };
            package = mkPackageOption pkgs config.nixpkgsPackage {
              nullable = true;
            };
            path = mkOption {
              type = types.nullOr types.path;
              default = if config.package != null then "${config.package}/bin" else null;
            };
          };
        }
      );
    };

in
{

  imports = [ ./languages.nix ];

  options = {
    emitPaths = mkEnableOption "emit paths";

    languages = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkEnableOption "the language";
            formatters = mkOption {
              type = types.listOf (types.enum (builtins.attrNames options.formatters));
            };
          };
        }
      );
      default = { };
      description = "An attrset of languages";
    };

    neededFormatters = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    usedLanguages = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    formatters =
      let
        files = builtins.readDir ./formatters;
        formatters = map (name: lib.removeSuffix ".nix" name) (
          lib.filter (name: files.${name} == "regular") (builtins.attrNames files)
        );
      in
      lib.genAttrs formatters mkFormatter;

    output = mkOption {
      readOnly = true;
    };

    output-json = mkOption {
      readOnly = true;
    };
  };
  config = {
    neededFormatters = lib.unique (
      lib.concatLists (
        builtins.map (lang: config.output.languages.${lang}.formatters) (
          builtins.attrNames config.output.languages
        )
      )
    );

    formatters = lib.genAttrs config.neededFormatters (keys: {
      enable = true;
    });

    languages = lib.genAttrs config.usedLanguages (keys: {
      enable = true;
    });

    output = {
      inherit (config) neededFormatters;

      languages = lib.mapAttrs (key: val: { inherit (val) formatters; }) (
        lib.filterAttrs (key: val: val.enable) config.languages
      );

      formatters = lib.mapAttrs (
        key: val:
        {
          inherit (val) command args;
        }
        // (if config.emitPaths then { inherit (val) path; } else { })
      ) (lib.filterAttrs (key: val: val.enable) config.formatters);
    };

    output-json = pkgs.writeText "ash.json" (builtins.toJSON (config.output));
  };
}
