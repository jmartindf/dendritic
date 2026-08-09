_: {

  config = {

    flake.modules.nixos.services =
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

          desertflood.services.koreader-sync = {
            enable = lib.mkEnableOption "serving koreader-sync, ";

            host = lib.mkOption {
              type = lib.types.str;
              default = "127.0.0.1";
              description = "Bind to which interface";
            };

            port = lib.mkOption {
              type = lib.types.int;
              default = nixOScfg.desertflood.globals.ports.koreader-sync;
              description = "Bind to which local port";
            };

            disableRegistration = lib.mkOption {
              type = lib.types.bool;
              default = true;
              example = false;
              description = ''
                When set to `true` the sync server will respond with an `User
                registration is disabled` error message when trying to create
                a new user. This is useful if you expose your sync server to
                the public internet, but don't want anyone to be able to register
                a user. This is a feature that is not available in the official
                sync server.
              '';
            };

          };
        };

        config =
          let
            svcConfig = nixOScfg.desertflood.services.koreader-sync;
            baseName = "koreader-sync";
            workDir = "/var/lib/${baseName}";
          in
          lib.mkIf nixOScfg.desertflood.services.koreader-sync.enable {

            age.secrets.koreader-sync-env = {
              rekeyFile = ./koreader-sync.env.age;
              name = "koreader-sync.env";
              mode = "0600";

              generator.script =
                let
                  envTemplate = ./koreader-sync.env;
                in
                { lib, ... }: # bash
                ''
                  cat ${lib.escapeShellArg envTemplate} | op inject
                '';
            };

            desertflood.networking.services.koreader-sync = { };

            environment.systemPackages = [ pkgs.local.koreader-sync ];

            systemd.services.${baseName} = {

              description = "KOReader sync-server, written in TypeScript";
              documentation = [ "https://github.com/nperez0111/koreader-sync" ];

              wantedBy = [ "multi-user.target" ];

              after = [
                "network.target"
              ];
              requires = [ "network.target" ];

              startLimitIntervalSec = 14400;
              startLimitBurst = 10;

              environment = {
                PORT = "${toString svcConfig.port}";
                DISABLE_USER_REGISTRATION = "${if svcConfig.disableRegistration then "true" else "false"}";
                NODE_ENV = "production";
              };

              serviceConfig = {
                User = baseName;
                Group = baseName;
                DynamicUser = true;

                WorkingDirectory = workDir;
                ReadWritePaths = workDir;
                StateDirectory = "${baseName} ${baseName}/data"; # under /var/lib. Sticks around permanently

                EnvironmentFile = nixOScfg.age.secrets.koreader-sync-env.path;

                ExecStart = "${pkgs.local.koreader-sync}/bin/koreader-sync";

                Restart = "on-failure";
                RestartPreventExitStatus = 1;
                RestartSec = "5s";

                TimeoutStopSec = "5s";

                LimitNOFILE = 1048576;

                PrivateTmp = true;

                ProtectSystem = "strict";
                ProtectHome = "read-only";
              };

            };

          };

      };

  };

}
