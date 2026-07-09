{
  description = "An empty flake template that you can adapt to your own environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ash.url = "github:kalhauge/a.sh";
    ash.inputs.nixpkgs.follows = "nixpkgs";
    ash.inputs.flake-parts.follows = "flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{ self, config, ... }:
      {
        imports = [
          inputs.ash.flakeModules.default
        ];

        flake = {
          # Your flake goes here
        };

        perSystem =
          { config, ... }:
          {
            ash = {
              enable = true;
              config = {
                emitPaths = true;
                usedLanguages = [
                  "Git Attributes"
                  "Nix"
                  "Ignore List"
                  "JSON"
                  "Markdown"
                ];

              };
            };

            packages = {
              # Your packages
            };
          };
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
      }
    );
}
