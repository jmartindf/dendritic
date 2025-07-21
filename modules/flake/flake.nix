{ inputs, lib, ... }:
{
  imports = [
    inputs.devshell.flakeModule
    inputs.flake-parts.flakeModules.modules
    (inputs.dendrix.vic-vix.filter (lib.hasSuffix "mk-os.nix"))
  ];

  config = {

    systems = import inputs.systems;

    flake = {

      nixosConfigurations = {
        richard = inputs.self.lib.mk-os.linux "richard";
      };

    };
  };
}
