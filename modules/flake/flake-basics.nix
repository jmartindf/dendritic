{ inputs, ... }:
{
  config = {

    systems = import inputs.systems;

    flake-file.inputs = {
      flake-utils = {
        url = "github:numtide/flake-utils";
        inputs.systems.follows = "systems";
      };

      flake-compat.url = "github:edolstra/flake-compat";

      systems.url = "github:jmartindf/nix-systems-modern-default";
    };

  };
}
