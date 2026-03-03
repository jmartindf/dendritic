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

          desertflood.services.kosync-dotnet = {
            enable = lib.mkEnableOption "serving kosync-dotnet, ";

            host = lib.mkOption {
              type = lib.types.str;
              default = "127.0.0.1";
              description = "Bind to which interface";
            };

            port = lib.mkOption {
              type = lib.types.int;
              default = nixOScfg.desertflood.globals.ports.kosync-dotnet;
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

            trustedProxies = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [
                "1.2.3.4"
                "::1"
              ];
              description = ''
                List one or more trusted proxies. If this is set, when a request
                comes through a trusted proxy, the X-Forwarded-For header will be
                checked for the client\'s real IP address to use in logging. If
                TRUSTED_PROXIES is not set, or if a request does not come through
                a trusted proxy, the request\'s source IP address will be used for
                logging. Requests that do not come through a trusted proxy when
                TRUSTED_PROXIES is set will be marked with an asterisk (*) in the
                logs.
              '';
            };

          };
        };

        config =
          let
            svcConfig = nixOScfg.desertflood.services.kosync-dotnet;
            baseName = "kosync-dotnet";
            workDir = "/var/lib/${baseName}";
            proxyString = lib.concatStringsSep "," svcConfig.trustedProxies;
          in
          lib.mkIf nixOScfg.desertflood.services.kosync-dotnet.enable {

            age.secrets.kosync-dotnet-env = {
              rekeyFile = ./kosync-dotnet.env.age;
              name = "kosync-dotnet.env";
              mode = "0600";

              generator.script =
                let
                  envTemplate = ./kosync-dotnet.env;
                in
                { lib, ... }: # bash
                ''
                  cat ${lib.escapeShellArg envTemplate} | op inject
                '';
            };

            desertflood.networking.services.kosync-dotnet = { };

            environment.systemPackages = [ pkgs.local.kosync-dotnet ];

            systemd.services.${baseName} = {

              description = "KOReader sync server, written in .NET";
              documentation = [ "https://github.com/jberlyn/kosync-dotnet" ];

              wantedBy = [ "multi-user.target" ];

              after = [
                "network.target"
              ];
              requires = [ "network.target" ];

              startLimitIntervalSec = 14400;
              startLimitBurst = 10;

              environment = {
                ASPNETCORE_HTTP_PORTS = "${toString svcConfig.port}";
                REGISTRATION_DISABLED = "${if svcConfig.disableRegistration then "true" else "false"}";
              }
              // lib.optionalAttrs (svcConfig.trustedProxies != [ ]) { TRUSTED_PROXIES = proxyString; };

              serviceConfig = {
                User = baseName;
                Group = baseName;
                DynamicUser = true;

                WorkingDirectory = workDir;
                ReadWritePaths = workDir;
                StateDirectory = "${baseName} ${baseName}/data"; # under /var/lib. Sticks around permanently

                EnvironmentFile = nixOScfg.age.secrets.kosync-dotnet-env.path;

                ExecStart = "${pkgs.local.kosync-dotnet}/bin/Kosync";

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
