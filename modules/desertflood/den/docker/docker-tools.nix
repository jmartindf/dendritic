{ df, ... }:
{
  df.cli.tools.docker = {
    description = "Tools for managing Docker, Docker Compose, and containers.";

    includes = [
      df.cli.tools.docker._ # Automatically include all child tools
    ];

    lazydocker = {

      nixos = { pkgs, ... }: {
        config.environment.systemPackages =
          (builtins.traceVerbose "df.cli.tools.docker.lazydocker nixos active")
            [
              pkgs.lazydocker
            ];
      };

      homeManager.config.programs.lazydocker =
        builtins.traceVerbose "df.cli.tools.docker.lazydocker homeManager active"
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
  };
}
