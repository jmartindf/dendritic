{ inputs, lib, ... }:
{
  imports = [
    inputs.agenix-rekey.flakeModule
  ];

  config = {

    systems = import inputs.systems;

    perSystem =
      { config, pkgs, ... }:
      {
        # add agenix-rekey to the flake's dev shell
        devshells.default = {

          packages = [
            pkgs.age
            pkgs.age-plugin-yubikey
          ];

          commands = [
            {
              inherit (config.agenix-rekey) package;
              help = "Edit, generate and rekey secrets";
            }
          ];
        };

      };
  };
}
