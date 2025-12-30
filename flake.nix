{
  description = "An empty flake template that you can adapt to your own environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "aarch64-darwin" # 64-bit ARM macOS
        "x86_64-darwin" # 64-bit Intel/AMD Linux
      ];

      forEachSystem =
        {
          systems ? supportedSystems,
          do,
        }:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          do {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
            };
            lib = inputs.nixpkgs.lib;
            self' = inputs.nixpkgs.lib.mapAttrs (k: v: v.${system}) self;
          }
        );
    in
    {
      packages = forEachSystem {
        do =
          { pkgs, ... }:
          {
            default = pkgs.callPackage ./nix { };
            ash_json = pkgs.writeText "ash.json" (
              builtins.toJSON {
                languages = [
                  {
                    name = "Markdown";
                    formatters = [
                      {
                        command = pkgs.lib.getExe pkgs.mdformat;
                        args = [ "-" ];
                      }
                    ];
                  }
                  {
                    name = "TOML";
                    formatters = [
                      {
                        command = pkgs.lib.getExe pkgs.taplo;
                        args = [
                          "fmt"
                          "-"
                        ];
                      }
                    ];
                  }
                ];
              }
            );
          };
      };

      devShells = forEachSystem {
        do =
          {
            pkgs,
            system,
            self',
            ...
          }:
          {
            default = pkgs.mkShellNoCC { };
          };
      };

      checks = forEachSystem {
        do =
          {
            system,
            pkgs,
            self',
            ...
          }:
          {
            ash = self'.packages.default;
          };
      };
    };
}
