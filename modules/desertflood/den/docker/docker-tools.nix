{
  den,
  df,
  inputs,
  config,
  lib,
  ...
}:
{
  df.cli._.tools._.docker = {
    description = "Tools for managing Docker, Docker Compose, and containers.";

    includes = [ ];

    nixos =
      { pkgs, ... }:
      {
        config.environment.systemPackages = [
          pkgs.lazydocker
        ];
      };

    darwin =
      { pkgs, ... }:
      {
        config.environment.systemPackages = [
          pkgs.lazydocker
        ];
      };

    homeManager.config.programs.lazydocker =
      builtins.traceVerbose "df.cli._.tools._.docker homeManager active"
        {
          enable = true;

          settings.customCommands.containers = [
            {
              name = "shell";
              attach = true;
              command = "docker exec -it {{ .Container.ID }} /bin/sh";
            }
          ];
        };
  };

  flake.modules.nixos.docker-tools =
    { pkgs, ... }:
    {
      config.environment.systemPackages = [
        pkgs.lazydocker
      ];
    };

}
