{
  config,
  den,
  lib,
  inputs,
  self,
  ...
}:
let
  inherit (inputs) deploy-rs;
  flakeCfg = config;
in
{
  config = {

    flake =
      { config, ... }:
      {
        deploy.nodes = lib.mapAttrs (host: options: {
          hostname = options.fqdn;
          profiles.system = {
            user = "root";
            sshUser = "nixos";

            autoRollback = true;
            magicRollback = true;

            fastConnection = true;

            activationTimeout = 600; # 10 minutes
            confirmTimeout = 120; # 2 minutes

            path = deploy-rs.lib.${options.system}.activate.nixos self.nixosConfigurations.${host};
          };
        }) flakeCfg.desertflood.hosts.hosts;
      };

    perSystem =
      {
        system,
        inputs',
        ...
      }:
      {
        checks = deploy-rs.lib.${system}.deployChecks self.deploy;

        devshells.default = {

          packages = [
            inputs'.deploy-rs.packages.default
          ];

          commands = [
            {
              package = inputs'.deploy-rs.packages.default;
              help = "Deploy this nix config to nodes";
            }
          ];

        };

      };

    flake-file.inputs.deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };

    };
  };
}
