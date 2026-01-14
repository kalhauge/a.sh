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

  superconfig = config;

  nixFilesOf =
    dir:
    let
      files = builtins.readDir dir;
    in
    map (name: lib.removeSuffix ".nix" name) (
      lib.filter (name: files.${name} == "regular") (builtins.attrNames files)
    );

  mkTool =
    {
      kind,
      config_file,
      name,
    }:
    mkOption {
      default = { };
      description = "Configuration for ${kind} ${name}";
      type = types.submodule (
        { config, ... }:
        {
          imports = [
            (
              let
                m = import config_file;
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

  mkFormatter =
    name:
    mkTool {
      kind = "formatter";
      name = name;
      config_file = ./formatters/${name}.nix;
    };

  mkServer =
    name:
    mkTool {
      kind = "server";
      name = name;
      config_file = ./servers/${name}.nix;
    };
in
{

  imports = [ ./languages.nix ];

  options = {
    emitPaths = mkEnableOption "emit paths";
    enableAllLanguages = mkEnableOption "enables all languages";

    languages = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkEnableOption "the language";
            formatters = mkOption {
              type = types.listOf (types.enum (builtins.attrNames options.formatters ++ [ "skip" ]));
              default = [ ];
            };
            servers = mkOption {
              type = types.listOf (types.enum (builtins.attrNames options.servers ++ [ "skip" ]));
              default = [ ];
            };
          };
          config = {
            enable = mkIf config.enableAllLanguages true;
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

    neededServers = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    usedLanguages = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    formatters = lib.genAttrs (nixFilesOf ./formatters) mkFormatter;

    servers = lib.genAttrs (nixFilesOf ./servers) mkServer;

    output = mkOption {
      readOnly = true;
    };

    output-json = mkOption {
      type = types.package;
      readOnly = true;
    };

    output-shell = mkOption {
      type = types.package;
      readOnly = true;
    };
  };
  config = {
    neededFormatters = builtins.filter (lang: lang != "skip") (
      lib.unique (
        lib.concatLists (
          builtins.map (lang: config.output.languages.${lang}.formatters) (
            builtins.attrNames config.output.languages
          )
        )
      )
    );

    neededServers = builtins.filter (lang: lang != "skip") (
      lib.unique (
        lib.concatLists (
          builtins.map (lang: config.output.languages.${lang}.servers) (
            builtins.attrNames config.output.languages
          )
        )
      )
    );

    formatters = lib.genAttrs config.neededFormatters (keys: {
      enable = true;
    });

    servers = lib.genAttrs config.neededServers (keys: {
      enable = true;
    });

    languages = lib.genAttrs config.usedLanguages (keys: {
      enable = true;
    });

    output = {
      inherit (config) neededFormatters;
      languages = lib.filterAttrs (key: val: val.enable) config.languages;
    }
    // lib.genAttrs [ "formatters" "servers" ] (
      kind:
      lib.mapAttrs (
        key: val:
        {
          inherit (val) command args;
        }
        // (if config.emitPaths && builtins.hasAttr "path" val then { inherit (val) path; } else { })
      ) (lib.filterAttrs (key: val: val.enable) config.${kind})
    );

    output-json = pkgs.writeText "ash.json" (builtins.toJSON (config.output));
    output-shell = pkgs.callPackage ./default.nix { ash-config = config.output-json; };
  };
}
