{
  den,
  df,
  inputs,
  config,
  lib,
  ...
}:
let
  flakeCfg = config;
in
{
  df.docker-server =
    { host, ... }:
    {
      includes = [
        df.cli._.tools._.docker # Useful tools such as lazydocker
      ];

      description = "Manage and run containers through Docker";

      nixos =
        { pkgs, ... }:
        {
          environment.systemPackages = builtins.trace "df.docker-server active" [
            pkgs.docker-color-output
            pkgs.docker_28
            pkgs.local.vackup
          ];

          virtualisation.docker = {
            enable = true;
            package = pkgs.docker_28;
            logDriver = "journald";
            storageDriver = "overlay2";
            enableOnBoot = true;
          };
        };

      darwin = { };
      homeManager = { };
    };

  flake.modules.nixos.docker-server =
    { pkgs, ... }:
    {
      imports = [
        flakeCfg.flake.modules.nixos.dockeras
        flakeCfg.flake.modules.nixos.docker-tools
      ];

      environment.systemPackages = builtins.trace "df.docker-server active" [
        pkgs.docker-color-output
        pkgs.docker_28
        pkgs.local.vackup
      ];

      virtualisation.docker = {
        enable = true;
        package = pkgs.docker_28;
        logDriver = "journald";
        storageDriver = "overlay2";
        enableOnBoot = true;
      };
    };
}
