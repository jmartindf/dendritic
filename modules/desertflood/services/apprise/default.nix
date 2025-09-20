_: {

  config = {

    flake.modules.nixos.apprise-api =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        nixOScfg = config;
      in
      {

        options = {

          desertflood.services.apprise-api = {
            enable = lib.mkEnableOption "serving apprise-api, a lightweight REST framework that wraps the Apprise Notification Library";

            host = lib.mkOption {
              type = lib.types.str;
              default = "127.0.0.1";
              description = "Bind to which interface";
            };

            port = lib.mkOption {
              type = lib.types.int;
              default = 8000;
              description = "Bind to which local port";
            };

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
            svcConfig = nixOScfg.desertflood.services.apprise-api;
            baseName = "apprise-api";
            workDir = "/var/lib/${baseName}";
            webConfig = nixOScfg.desertflood.networking.services.apprise-api;
          in
          lib.mkIf nixOScfg.desertflood.services.apprise-api.enable {

            # age.secrets.apprise-api-secrets = {
            #   rekeyFile = ./secrets.env.age;
            #   owner = "apprise-api";
            #   group = "apprise-api";
            # };

            desertflood.networking.services.apprise-api = { };

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
                LOG_LEVEL = "${svcConfig.log-level}";
                APPRISE_CONFIG_LOCK = "no";
                BASE_URL = lib.optionalString (webConfig.path != "") webConfig.path;
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
                  "127.0.0.1:${toString svcConfig.port}"
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
