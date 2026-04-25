{
  description = "An empty flake template that you can adapt to your own environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    ash.url = "github:kalhauge/a.sh";
    ash.inputs.nixpkgs.follows = "nixpkgs";
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

      lib = inputs.nixpkgs.lib;
      ash = inputs.ash.lib;

      forEachSystem =
        {
          systems ? supportedSystems,
          do,
        }:
        inputs.nixpkgs.lib.genAttrs systems (
          system:
          do {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
            };
            self' = inputs.nixpkgs.lib.mapAttrs (k: v: v.${system}) self;
          }
        );
    in
    {
      packages = forEachSystem {
        do =
          { pkgs, self', ... }:
          {
            ash-config = ash.mkAshConfig pkgs {
              emitPaths = true;
              usedLanguages = [
                "Git Attributes"
                "Nix"
              ];
            };
          };
      };

      formatter = ash.mkFormatterForEachSystem {
        systems = supportedSystems;
      };

      checks = forEachSystem {
        do =
          {
            self',
            pkgs,
            system,
            ...
          }:
          {
            formatcheck = self.lib.mkFormatCheck { inherit system self; };
          };
      };
    };
}
