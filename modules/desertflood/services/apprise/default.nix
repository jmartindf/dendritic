_:
let
  apprisePort = 8000;
  appriseAddr = "127.0.0.1";
  appriseHost = "apprise.desertflood.com";
in
{

  df.services.apprise = { host, ... }: {

    traefik-apps = {
      apprise = {
        rule = "Host(`${appriseHost}`)";
        url = "http://${appriseAddr}:${toString apprisePort}";
        middlewares = "chain-basic-auth@file";
      };
    };

    traefik-routers = {
      apprise-static = {
        rule = "Host(`${appriseHost}`) && PathPrefix(`/s/`)";
        middlewares = "chain-basic-auth@file";
        service = "sites-static-svc@file";
      };
    };

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        baseName = "apprise-api";
        workDir = "/var/lib/${baseName}";
        logLevel = config.desertflood.services.apprise-api.log-level;
      in
      {

        options = {

          desertflood.services.apprise-api = {
            log-level = lib.mkOption {
              type = lib.types.enum [
                "CRITICAL"
                "ERROR"
                "WARNING"
                "INFO"
                "DEBUG"
              ];
              default = "WARNING";
              description = "How much detail to log";
            };
          };
        };

        config =
          let
            caddyPort = host.desertflood.globals.ports.caddy-static;
          in
          {

            desertflood.services.caddy.settings.site-blocks = # caddy
              ''
                http://apprise.desertflood.com:${toString caddyPort} {
                  bind 127.0.0.1
                  log
                  cache

                  handle_path /s/* {
                    root ${pkgs.local.apprise-api}/webapp/static
                    file_server
                  }
                }
              '';

            # age.secrets.apprise-api-secrets = {
            #   rekeyFile = ./secrets.env.age;
            #   owner = "apprise-api";
            #   group = "apprise-api";
            # };

            environment.systemPackages = [ pkgs.local.apprise-api ];

            users.users.${baseName} = {
              createHome = true;
              description = "Apprise notification server";
              group = "${baseName}";
              home = "${workDir}";
              isSystemUser = true;
              shell = null;
            };

            users.groups.${baseName} = { };

            systemd.services.${baseName} = {
              description = "Apprise notification server";
              documentation = [ "https://github.com/caronc/apprise-api" ];

              wantedBy = [ "multi-user.target" ];

              after = [
                "network.target"
              ];
              requires = [ "network.target" ];

              startLimitIntervalSec = 14400;
              startLimitBurst = 10;

              environment = {
                APPRISE_CONFIG_DIR = "${workDir}";
                APPRISE_STORAGE_DIR = "${workDir}/store";
                APPRISE_ATTACH_DIR = "${workDir}/attach";
                LOG_LEVEL = "${logLevel}";
                APPRISE_CONFIG_LOCK = "no";
                BASE_URL = "";
              };

              serviceConfig = {
                User = "${baseName}";
                Group = "${baseName}";

                ReadWritePaths = "${workDir}";
                StateDirectory = "${baseName}";
                LogsDirectory = "${baseName}";
                # RuntimeDirectory = "${baseName}";
                # ConfigurationDirectory = "${baseName}";

                # EnvironmentFile = nixOScfg.age.secrets.apprise-api-secrets.path;

                ExecStart = lib.concatStringsSep " " [
                  "${pkgs.local.apprise-api}/bin/apprise-api"
                  "--bind"
                  "${appriseAddr}:${toString apprisePort}"
                ];

                Restart = "on-failure";
                RestartPreventExitStatus = 1;
                RestartSec = "5s";

                TimeoutStopSec = "5s";

                LimitNOFILE = 1048576;

                PrivateTmp = true;

                ProtectSystem = "full";
                ProtectHome = true;
              };

            };

          };

      };

  };

}
