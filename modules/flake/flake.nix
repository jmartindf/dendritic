{ inputs, lib, ... }:
{
  imports = [
    (inputs.dendrix.vic-vix.filter (lib.hasSuffix "mk-os.nix"))
    inputs.devshell.flakeModule
    inputs.flake-parts.flakeModules.modules
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  config = {

    systems = import inputs.systems;

    perSystem = {
      pkgsDirectory = ../../pkgs/by-name;
    };

    flake = {

      nixosConfigurations = {
        richard = inputs.self.lib.mk-os.linux "richard";
      };

    };
  };
}
