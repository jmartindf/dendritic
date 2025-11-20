{
  config,
  inputs,
  lib,
  ...
}:
let
  flakeCfg = config;
  mkServiceSecrets =
    secretHolder: names:
    lib.genAttrs names (name: {
      rekeyFile = ./secrets/${name}.age;
      owner = secretHolder;
      group = secretHolder;
    });
in
{
  flake.modules.nixos.services =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      netCfg = nixOScfg.desertflood.networking;
      svcsConfig = nixOScfg.desertflood.services;
    in
    {

      options = {

        desertflood.services.forgejo = {
          enable = lib.mkEnableOption "Forgejo shared git hosting";

          mode = lib.mkOption {
            type = lib.types.enum [
              "dev"
              "prod"
            ];
            default = "dev";
            description = "Development mode or production mode";
          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "forgejo";
            description = "The user to run under and to access Git-over-SSH with";
          };

          disableSSH = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Disable SSH access to Git";
          };

          sshPort = lib.mkOption {
            type = lib.types.int;
            default = 22;
            description = "The port SSH-Git is available under";
          };
        };

      };

      config =
        let
          forgejoUser = svcsConfig.forgejo.user;
          customUser = svcsConfig.forgejo.user != "forgejo";
          dbName = "forgejo";
          dbUser = "forgejo";
        in
        lib.mkIf svcsConfig.forgejo.enable {

          desertflood = {

            services.forgejo = { };
            networking.services.forgejo = { };

            services.postgresql.enable = true;

          };

          environment.defaultPackages = [ pkgs.local.forgejo-migrate ];

          age.secrets = mkServiceSecrets forgejoUser [
            "forgejo-password-sunfish"
            "forgejo-password-mirrors"
            "forgejo-password-jmartindf"
            "forgejo-minio_access_key_id"
            "forgejo-minio_secret_access_key"
            "forgejo-minio_bucket"
            "forgejo-lfs_jwt_secret"
            "forgejo-security_secret_key"
            "forgejo-security_internal_token"
          ];

          users.users = lib.mkIf customUser {
            ${forgejoUser} = {
              home = nixOScfg.services.forgejo.stateDir;
              useDefaultShell = true;
              group = forgejoUser;
              isSystemUser = true;
            };
          };

          users.groups = lib.mkIf customUser {
            ${forgejoUser} = { };
          };

          services = {

            postgresql = {

              authentication = lib.optionalString customUser ''
                local forgejo all ident map=forgejo-users
              '';

              identMap = lib.optionalString customUser ''
                forgejo-users ${forgejoUser} forgejo
              '';

              ensureDatabases = [ dbName ];
              ensureUsers = [
                {
                  name = dbUser;
                  ensureDBOwnership = true;
                }
              ];
            };

            forgejo = {
              enable = true;
              package = pkgs.forgejo-lts;

              user = forgejoUser;

              database = {
                user = dbUser;
                type = "postgres";
                name = dbName;
                createDatabase = false;
                socket = "/run/postgresql";
                # passwordFile = nixOScfg.age.secrets.forgejo-password-database.path;
              };

              settings = {
                DEFAULT = {
                  APP_NAME = "Desertforge: Code Hosting by Desertflood";
                  RUN_MODE = svcsConfig.forgejo.mode;
                };

                cache = {
                  ADAPTER = "twoqueue";
                  HOST = ''{"size":100, "recent_ratio":0.25, "ghost_ratio":0.5}'';
                };

                cron = {
                  ENABLED = true;
                };

                log = {
                  MODE = "file";
                };

                picture = {
                  GRAVATAR_SOURCE = "gravatar";
                  ENABLE_FEDERATED_AVATAR = true;
                };

                repository = {
                  DEFAULT_BRANCH = "main";
                  DEFAULT_CLOSE_ISSUES_VIA_COMMITS_IN_ANY_BRANCH = false;
                  DEFAULT_PRIVATE = true;
                  DEFAULT_REPO_UNITS = "repo.code,repo.releases,repo.issues,repo.pulls,repo.projects,repo.packages";
                  DEFAULT_PUSH_CREATE_PRIVATE = true;

                  DISABLE_HTTP_GIT = false;

                  ENABLE_PUSH_CREATE_ORG = false;
                  ENABLE_PUSH_CREATE_USER = true;

                  PREFERRED_LICENSES = "BlueOak-1.0.0,BSD-2-Clause-Patent,BSD-2-Clause,MIT,MIT-Modern-Variant,GPL-3.0-or-later,AGPL-3.0-or-later";

                  USE_COMPAT_SSH_URI = true;
                };

                "repository.signing" = {
                  DEFAULT_TRUST_MODEL = "committer";
                };

                security.LOGIN_REMEMBER_DAYS = 365;

                server = {
                  LFS_START_SERVER = true;
                  LFS_JWT_SECRET_URI = "file:${nixOScfg.age.secrets.forgejo-lfs_jwt_secret.path}";
                  DISABLE_SSH = svcsConfig.forgejo.disableSSH;
                  DOMAIN = "${netCfg.services.forgejo.fqdn}";
                  ENABLE_GZIP = true;
                  HTTP_ADDR = "127.0.0.1";
                  HTTP_PORT = 3030;
                  LANDING_PAGE = "explore";
                  OFFLINE_MODE = false;
                  ROOT_URL = "${netCfg.services.forgejo.fullURL}";
                  SSH_DOMAIN = "${netCfg.services.forgejo.fqdn}";
                  SSH_PORT = svcsConfig.forgejo.sshPort;
                  SSH_USER = svcsConfig.forgejo.user;
                };

                service = {
                  DISABLE_REGISTRATION = true;
                  ENABLE_CAPTCHA = false;
                  MAX_USER_REDIRECTS = 5;
                  USERNAME_COOLDOWN_PERIOD = 7;
                };

                session = {
                  PROVIDER = "db";
                  COOKIE_NAME = "lfg_forgejo";
                  COOKIE_SECURE = true;
                  SESSION_LIFE_TIME = 14 * 86400; # 14 days
                };

                openid = {
                  ENABLE_OPENID_SIGNIN = false;
                  ENABLE_OPENID_SIGNUP = false;
                };

                storage = {
                  STORAGE_TYPE = "minio";
                  MINIO_ENDPOINT = "s3.us-west-001.backblazeb2.com";
                  MINIO_LOCATION = "us-west-001";
                  MINIO_USE_SSL = true;
                  MINIO_INSECURE_SKIP_VERIFY = false;
                  SERVE_DIRECT = false;
                  MINIO_CHECKSUM_ALGORITHM = "md5";
                };

                time.DEFAULT_UI_LOCATION = nixOScfg.time.timeZone;

                ui = {
                  DEFAULT_SHOW_FULL_NAME = false;
                  ONLY_SHOW_RELEVANT_REPOS = true;
                  PREFERRED_TIMESTAMP_TENSE = "mixed";
                  THEMES = lib.concatStringsSep "," [
                    "catppuccin-blue-auto"
                    "catppuccin-flamingo-auto"
                    "catppuccin-green-auto"
                    "catppuccin-lavender-auto"
                    "catppuccin-maroon-auto"
                    "catppuccin-mauve-auto"
                    "catppuccin-mocha-blue"
                    "catppuccin-mocha-flamingo"
                    "catppuccin-mocha-green"
                    "catppuccin-mocha-lavender"
                    "catppuccin-mocha-maroon"
                    "catppuccin-mocha-mauve"
                    "catppuccin-mocha-peach"
                    "catppuccin-mocha-pink"
                    "catppuccin-mocha-red"
                    "catppuccin-mocha-rosewater"
                    "catppuccin-mocha-sapphire"
                    "catppuccin-mocha-sky"
                    "catppuccin-mocha-teal"
                    "catppuccin-mocha-yellow"
                    "catppuccin-peach-auto"
                    "catppuccin-pink-auto"
                    "catppuccin-red-auto"
                    "catppuccin-rosewater-auto"
                    "catppuccin-sapphire-auto"
                    "catppuccin-sky-auto"
                    "catppuccin-teal-auto"
                    "catppuccin-yellow-auto"
                    "forgejo-auto"
                    "forgejo-auto-deuteranopia-protanopia"
                    "forgejo-auto-tritanopia"
                    "forgejo-dark"
                    "forgejo-dark-deuteranopia-protanopia"
                    "forgejo-dark-tritanopia"
                    "forgejo-light"
                    "forgejo-light-deuteranopia-protanopia"
                    "forgejo-light-tritanopia"
                    "gitea-auto"
                    "gitea-dark"
                    "gitea-light"
                  ];
                };

                "ui.meta" = {
                  AUTHOR = "jmartindf";
                  DESCRIPTION = "jmartindf's self-hosted code forge";
                };

              }; # end `forgejo` settings block

              secrets = {

                security.SECRET_KEY = lib.mkForce nixOScfg.age.secrets.forgejo-security_secret_key.path;
                security.INTERNAL_TOKEN = lib.mkForce nixOScfg.age.secrets.forgejo-security_internal_token.path;

                storage = {
                  MINIO_ACCESS_KEY_ID = nixOScfg.age.secrets.forgejo-minio_access_key_id.path;
                  MINIO_SECRET_ACCESS_KEY = nixOScfg.age.secrets.forgejo-minio_secret_access_key.path;
                  MINIO_BUCKET = nixOScfg.age.secrets.forgejo-minio_bucket.path;
                };

              }; # end `forgejo` secrets block

            }; # end `forgejo` block

          }; # end `services` block

          # pattern taken from
          # https://github.com/dscv101/nyx/blob/d407b4d6e5ab7f60350af61a3d73a62a5e9ac660/modules/core/roles/server/system/services/forgejo.nix#L35
          # robots.txt taken from
          # https://codeberg.org/forgejo/forgejo/pulls/7387
          systemd.tmpfiles.rules =
            let
              # Disallow crawlers from indexing this site.
              robots = pkgs.writeText "forgejo-robots-txt" (lib.readFile ./robots.txt);
            in
            [
              "L+ ${nixOScfg.services.forgejo.customDir}/public/robots.txt - - - - ${robots.outPath}"
            ];

          # Taken from [@orangci](https://github.com/orangci)
          # [forgejo.nix](https://github.com/orangci/dots/blob/c84ee0a6116592961a5d935d4c961f11eb419c59/modules/server/forgejo.nix)
          systemd.services.forgejo.preStart =
            let
              theme = pkgs.fetchzip {
                url = "https://github.com/catppuccin/gitea/releases/download/v1.0.2/catppuccin-gitea.tar.gz";
                sha256 = "sha256-rZHLORwLUfIFcB6K9yhrzr+UwdPNQVSadsw6rg8Q7gs=";
                stripRoot = false;
              };
              inherit (nixOScfg.services.forgejo) stateDir;
              forgejoUsers = {
                sunfish = {
                  name = "sunfish";
                  isAdmin = true;
                  email = "joe+gitadmin@desertflood.com";
                  password = nixOScfg.age.secrets.forgejo-password-sunfish;
                };
                mirror = {
                  name = "mirror-owner";
                  isAdmin = false;
                  email = "joe+mirrors@desertflood.com";
                  password = nixOScfg.age.secrets.forgejo-password-mirrors;
                };
                jmartindf = {
                  name = "jmartindf";
                  isAdmin = false;
                  email = "joe@desertflood.com";
                  password = nixOScfg.age.secrets.forgejo-password-jmartindf;
                };
              };

              robots = ./robots.txt;
            in
            # bash
            ''
              # user setup
              admin="${lib.getExe config.services.forgejo.package} admin user"
            ''
            + lib.concatMapStringsSep "\n" (
              u: # bash
              ''
                if ! $admin list | grep "${u.name}"; then
                  $admin create ${lib.optionalString u.value.isAdmin "--admin"} --email "${u.value.email}" --must-change-password=false --username "${u.name}" --password "$(tr -d '\n' < ${u.value.password.path})"
                fi
              '') (lib.mapAttrsToList lib.nameValuePair forgejoUsers)
            # bash
            + ''

              # Theme setup
              rm -rf ${stateDir}/custom/public/assets
              mkdir -p ${stateDir}/custom/public/assets/css
              cp -r --no-preserve=mode,ownership ${theme}/* ${stateDir}/custom/public/assets/css
            '';

        }; # end Nix OS module config block

    }; # end `forgejo` Nix OS module
}
