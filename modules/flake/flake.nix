{ inputs, ... }:
{
  imports = [
    inputs.devshell.flakeModule
    inputs.flake-parts.flakeModules.modules
  ];

  config = {

    systems = import inputs.systems;

    flake = {
      nixosConfigurations = {
        richard = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.self.modules.nixos.richard
            inputs.lix-module.nixosModules.default
            {
              networking.hostName = "richard";
              nixpkgs.hostPlatform = {
                system = "x86_64-linux";
              };
              system.stateVersion = "25.05";
            }
          ];
        };
      };
    };
  };
}
