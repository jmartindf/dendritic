{
  lib,
  inputs,
  self,
  ...
}:
let
  inherit (inputs) deploy-rs;
in
{
  flake =
    { config, ... }:
    {
      # deploy.nodes = lib.mapAttrs (hostname: options: {
      #   hostname = builtins.head options.ipv4;
      #   profiles.system = {
      #     user = "root";
      #     path = deploy-rs.lib.${options.system}.activate.nixos self.nixosConfigurations.${hostname};
      #   };
      # }) config.hosts;
      deploy.nodes = {
        "richard" = {
          hostname = "richard.home.thosemartins.family";

          profiles.system = {
            sshUser = "root";
            user = "root";

            autoRollback = true;
            magicRollback = true;

            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."richard";
          };
        };
        "fossil" = {
          hostname = "fossil.home.thosemartins.family";

          profiles.system = {
            sshUser = "root";
            user = "root";

            autoRollback = true;
            magicRollback = true;

            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."fossil";
          };
        };
        "france" = {
          hostname = "france.df.fyi";

          profiles.system = {
            sshUser = "root";
            user = "root";

            autoRollback = true;
            magicRollback = true;

            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."france";
          };
        };
        "everest" = {
          hostname = "everest.df.fyi";

          profiles.system = {
            sshUser = "root";
            user = "root";

            autoRollback = true;
            magicRollback = true;

            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."everest";
          };
        };
      };
    };

  perSystem =
    {
      system,
      inputs',
      ...
    }:
    {
      checks = deploy-rs.lib.${system}.deployChecks self.deploy;

      devshells.default.packages = [
        inputs'.deploy-rs.packages.default
      ];

      devshells.default.commands = [
        {
          package = inputs'.deploy-rs.packages.default;
          help = "Deploy this nix config to nodes";
        }
      ];

    };
}
