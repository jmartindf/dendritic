{ inputs, lib, ... }:
{
  imports = [
    (inputs.dendrix.vic-vix.filter (lib.hasSuffix "mk-os.nix"))
    inputs.devshell.flakeModule
    inputs.flake-parts.flakeModules.modules
  ];

  config = {

    systems = import inputs.systems;

    perSystem =
      { config, pkgs, ... }:
      {
        # configure the flake's dev shell
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ config.agenix-rekey.package ];
        };

      };
  };
}
