{
  den,
  df,
  config,
  lib,
  ...
}:
let
  flakeCfg = config;

  dockerServerAspect = den.lib.take.exactly (
    { host }:
    {
      nixos =
        if host.capabilities.docker-server then
          { pkgs, ... }:
          builtins.traceVerbose "df.docker-server active" {
            environment.systemPackages = [
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
          }
        else
          builtins.traceVerbose "*not* df.docker-server active" { };

      darwin = { };
      homeManager = { };
    }
  );
in
{
  den.schema.conf = {
    options.capabilities.docker-server = lib.mkEnableOption "Does host provide docker containers?";
  };

  df.docker-server = den.lib.parametric {
    includes = [
      # create the `dockeras` system user and home-manager config
      df.dockeras
      # configure the server itself
      dockerServerAspect
    ];

    description = "Manage and run containers through Docker";
  };

  flake.modules.nixos.docker-server =
    { pkgs, ... }:
    {
      imports = [
        flakeCfg.flake.modules.nixos.dockeras
        flakeCfg.flake.modules.nixos.docker-tools
      ];

      environment.systemPackages = builtins.traceVerbose "df.docker-server active" [
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
