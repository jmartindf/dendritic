{ inputs, ... }:
{
  config = {

    perSystem =
      {
        inputs',
        ...
      }:
      {
        devshells.default.packages = [
          inputs'.bun2nix.packages.default
        ];
      };

    flake-file.inputs.bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

  };
}
