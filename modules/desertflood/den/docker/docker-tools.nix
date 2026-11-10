{
  den,
  df,
  inputs,
  config,
  lib,
  ...
}:
let
  osContext =
    { host }:
    {
      ${host.class} =
        { pkgs, ... }:
        {
          config.environment.systemPackages = [
            pkgs.lazydocker
          ];
        };
    };
in
{
  df.cli._.tools._.docker = {
    description = "Tools for managing Docker, Docker Compose, and containers.";

    includes = [
      osContext
      df.cli._.tools._.docker._.lazydocker
    ];

    # Home side only, for users: a { host } aspect included from a user
    # aspect would also add lazydocker to the host's packages (den#694).
    provides.lazydocker.homeManager.config.programs.lazydocker =
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
