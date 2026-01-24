{ inputs, ... }:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  config = {

    flake-file.inputs.pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

    perSystem = _: {
      # Configure pkgs-by-name-for-flake-parts
      pkgsDirectory = ../../pkgs/by-name;
    };

  };
}
