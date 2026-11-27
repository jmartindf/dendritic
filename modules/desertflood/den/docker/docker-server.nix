{
  df,
  lib,
  ...
}:
{
  den.schema.conf = {
    options.capabilities.server.docker = lib.mkEnableOption "Does host provide docker containers?";
  };

  den.schema.host.imports = [
    (
      { config, lib, ... }:
      {
        # Every docker server host is automatically a base server host, unless specified otherwise
        capabilities.server.enable = lib.mkDefault config.capabilities.server.docker;

        # Every docker host automatically includes the docker-server aspect
        includes = lib.mkIf config.capabilities.server.docker [
          df.docker-server
        ];
      }
    )
  ];

  df.docker-server = {

    description = "Manage and run containers through Docker";
    includes = [
      df.cli.tools.docker # Useful tools such as lazydocker
    ];

    nixos =
      { pkgs, ... }:
      builtins.traceVerbose "df.docker-server active" {
        environment.systemPackages = [
          pkgs.docker-color-output
          pkgs.docker_29
          pkgs.local.vackup
        ];

        virtualisation.docker = {
          enable = true;
          package = pkgs.docker_29;
          logDriver = "journald";
          storageDriver = "overlay2";
          enableOnBoot = true;
        };
      };
  };
}
