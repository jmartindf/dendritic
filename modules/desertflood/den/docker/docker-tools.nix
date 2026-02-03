{
  den,
  df,
  inputs,
  config,
  lib,
  ...
}:
let
  osContext = den.lib.take.exactly (
    { OS, host }:
    {
      ${host.class} =
        { pkgs, ... }:
        {
          config.environment.systemPackages = [
            pkgs.lazydocker
          ];
        };
    }
  );
in
{
  df.cli._.tools._.docker = den.lib.parametric {
    description = "Tools for managing Docker, Docker Compose, and containers.";

    includes = [ osContext ];

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
