{ inputs, ... }:
{
  imports = [
    inputs.agenix-rekey.flakeModule
  ];

  config = {

    systems = import inputs.systems;

    perSystem =
      { config, pkgs, ... }:
      {
        # add agenix-rekey to the flake's dev shell
        devshells.default = {

          packages = [
            pkgs.age
            pkgs.age-plugin-yubikey
            pkgs._1password-cli # also use `op` to inject secrets
          ];

          commands = [
            {
              inherit (config.agenix-rekey) package;
              help = "Edit, generate and rekey secrets";
            }
          ];
        };

      };

    flake-file.inputs = {

      agenix = {
        url = "github:ryantm/agenix";
        inputs = {
          nixpkgs.follows = "nixpkgs";
        };
      };

      agenix-rekey = {
        url = "github:oddlama/agenix-rekey";
        inputs = {
          nixpkgs.follows = "nixpkgs";
          devshell.follows = "devshell";
          flake-parts.follows = "flake-parts";
          pre-commit-hooks.follows = "git-hooks-nix";
          treefmt-nix.follows = "treefmt-nix";
          flake-compat.follows = "flake-compat";
        };
      };

    };

  };
}
