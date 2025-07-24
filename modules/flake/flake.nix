{ inputs, lib, ... }:
{
  imports = [
    inputs.agenix-rekey.flakeModule
    (inputs.dendrix.vic-vix.filter (lib.hasSuffix "mk-os.nix"))
    inputs.devshell.flakeModule
    inputs.flake-parts.flakeModules.modules
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  config = {

    systems = import inputs.systems;

    perSystem =
      { config, pkgs, ... }:
      {
        # Configure pkgs-by-name-for-flake-parts
        pkgsDirectory = ../../pkgs/by-name;

        # configure the flake's dev shell
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ config.agenix-rekey.package ];
        };

      };
  };
}
