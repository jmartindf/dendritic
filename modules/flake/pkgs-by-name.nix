{ inputs, ... }:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  config = {

    systems = import inputs.systems;

    perSystem = _: {
      # Configure pkgs-by-name-for-flake-parts
      pkgsDirectory = ../../pkgs/by-name;

    };
  };
}
