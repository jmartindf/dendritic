{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  config = {

    perSystem =
      {
        config,
        pkgs,
        system,
        ...
      }:
      {
        treefmt.config = {
          projectRootFile = "flake.nix";
          flakeCheck = true;
          programs = {
            nixfmt.enable = true;
          };
        };
      };

    flake-file.inputs.treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
}
