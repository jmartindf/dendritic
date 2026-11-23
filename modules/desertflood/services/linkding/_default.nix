{ inputs, ... }:
{
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  imports = [ ];

  options = { };

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
        svcsCfg = nixOScfg.desertflood.services;
        svcsNetCfg = nixOScfg.desertflood.networking.services;
        ldCfg = svcsCfg.linkding;
        ldNetCfg = svcsNetCfg.linkding;
        serviceName = "${nixOScfg.virtualisation.oci-containers.backend}-linkding";
        userid = 1605;
      in
      {

        imports = [ inputs.home-manager.nixosModules.home-manager ];

        options = {

          desertflood.services.linkding = {

            enable = lib.mkEnableOption "a self-hosted bookmark manager designed to be minimal, fast, and easy to set up.";

            port = lib.mkOption {
              type = lib.types.port;
              default = 9090;
              description = "custom port for the UWSGI server running in the container";
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = "linkding";
              description = "Run the service under this local user";
            };

            dataDir = lib.mkOption {
              type = lib.types.str;
              default = "/var/lib/linkding";
              description = "Store bookmarking data in this directory";
            };
          };

        };

        config = lib.mkIf ldCfg.enable {

          desertflood = {
            services.linkding = { };
            services.postgresql.enable = true;
            networking.services.linkding = { };
          };

          users.users.${ldCfg.user} = {
            home = ldCfg.dataDir;
            createHome = true;
            useDefaultShell = true;

            uid = userid;
            group = ldCfg.user;

            # only `normal` users can see journald logs
            # https://serverfault.com/a/1165779
            isSystemUser = false;
            isNormalUser = true;

            # need user sub-ids for podman to run a container
            # in a user's namespace
            autoSubUidGidRange = true;

            # you **need** `linger=true;` for containers with healthchecks
            linger = true;

            extraGroups = [ "podman" ];
          };

          users.groups.${ldCfg.user}.gid = userid;

          home-manager.users.${ldCfg.user} = {
            home.stateVersion = "25.05";

            home.activation = {
              mkDataDirectory =
                inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] # bash
                  ''
                    run mkdir -p $HOME/data
                  '';
            };

            services.podman = {
              enable = true;
              enableTypeChecks = true;

              containers.linkding = {
                image = "docker.io/sissbruecker/linkding@sha256:e4fbafee44388d8555e34ffdc507224302989265009fc82f5f2762b789f0385a";

                environmentFile = [ "${nixOScfg.age.secrets.linkding-env.path}" ];

                environment = {
                  LD_DB_ENGINE = "postgres";
                  LD_DB_DATABASE = ldCfg.user;
                  LD_DB_USER = ldCfg.user;
                  LD_DB_HOST = "/run/postgresql/";

                  LD_SERVER_PORT = "${builtins.toString ldCfg.port}";
                  LD_CSRF_TRUSTED_ORIGINS = "${ldNetCfg.protocol}://${ldNetCfg.fqdn}";
                  LD_SUPERUSER_NAME = "ldadmin";

                  LD_ENABLE_OIDC = "True";
                  OIDC_OP_AUTHORIZATION_ENDPOINT = "https://sso.desertflood.link/application/o/authorize/";
                  OIDC_OP_TOKEN_ENDPOINT = "https://sso.desertflood.link/application/o/token/";
                  OIDC_OP_USER_ENDPOINT = "https://sso.desertflood.link/application/o/userinfo/";
                  OIDC_OP_JWKS_ENDPOINT = "https://sso.desertflood.link/application/o/linkding/jwks/";
                  OIDC_RP_CLIENT_ID = "B8Ygn4HNrVrW4avHEufs3wstfvFI4F3OFVg80qW2";
                  OIDC_RP_SIGN_ALGO = "RS256";
                  OIDC_USE_PKCE = "True";
                };

                volumes = [
                  "${ldCfg.dataDir}/data:/etc/linkding/data"
                  "/run/postgresql:/run/postgresql"
                ];

                ports = [ "127.0.0.1:${builtins.toString ldCfg.port}:${builtins.toString ldCfg.port}" ];
              };
            };
          };

          age.secrets.linkding-pgpass = {
            rekeyFile = ./linkding-pgpass.age;
            owner = nixOScfg.systemd.services.postgresql.serviceConfig.User;
          };
          age.secrets.linkding-env = {
            rekeyFile = ./linkding-env.age;
            owner = ldCfg.user;
          };

          services.postgresql = {
            authentication = ''
              local linkding linkding scram-sha-256
            '';

            ensureDatabases = [ ldCfg.user ];
            ensureUsers = [
              {
                name = ldCfg.user;
                ensureDBOwnership = true;
              }
            ];
          };

          virtualisation = {
            containers.enable = true;
            podman.enable = true;
          };

          systemd.services.postgresql-setup.postStart =
            let
              password_file_path = nixOScfg.age.secrets.linkding-pgpass.path;
            in
            ''
              psql -tA <<'EOF'
                DO $$
                DECLARE password TEXT;
                BEGIN
                  password := trim(both from replace(pg_read_file('${password_file_path}'), E'\n', '''));
                  EXECUTE format('ALTER ROLE ${ldCfg.user} WITH PASSWORD '''%s''';', password);
                END $$;
              EOF
            '';

        };

      };

  };
}
