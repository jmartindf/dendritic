{ config, lib, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.forgejo =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      inherit (nixOScfg.desertflood.networking) webHost;
      netCfg = nixOScfg.desertflood.networking;
    in
    {
      options = {
      };

      config = {

        desertflood.networking.services.forgejo = { };

        services = {

          postgresql = {
            enable = true;
            package = pkgs.postgresql_17;
            ensureDatabases = [ "forgejo" ];
            ensureUsers = [
              {
                name = "forgejo";
                ensureDBOwnership = true;
              }
            ];
          };

          forgejo = {
            enable = true;

            settings = {
              DEFAULT = {
                APP_NAME = "Desertforge: Code Hosting by Desertflood";
                RUN_MODE = "dev";
              };

              cache = {
                ADAPTER = "twoqueue";
                HOST = ''{"size":100, "recent_ratio":0.25, "ghost_ratio":0.5}'';
              };

              cron = {
                ENABLED = true;
              };

              database = {
                user = "forgejo";
                type = "postgres";
                name = "forgejo";
                createDatabase = false;
                host = "127.0.0.1";
              };

              picture = {
                GRAVATAR_SOURCE = "gravatar";
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
                DISABLE_SSH = true;
                DOMAIN = "${netCfg.services.forgejo.fqdn}";
                ENABLE_GZIP = true;
                HTTP_ADDR = "127.0.0.1";
                HTTP_PORT = 3030;
                LANDING_PAGE = "explore";
                OFFLINE_MODE = false;
                ROOT_URL = "${netCfg.services.forgejo.fullURL}";
                SSH_DOMAIN = "${netCfg.services.forgejo.fqdn}";
              };

              service = {
                DISABLE_REGISTRATION = true;
                ENABLE_CAPTCHA = false;
                MAX_USER_REDIRECTS = 5;
                USERNAME_COOLDOWN_PERIOD = 7;
              };

              time.DEFAULT_UI_LOCATION = nixOScfg.time.timeZone;

              ui = {
                DEFAULT_SHOW_FULL_NAME = false;
                ONLY_SHOW_RELEVANT_REPOS = true;
                PREFERRED_TIMESTAMP_TENSE = "mixed";
              };

              ui.meta = {
                AUTHOR = "jmartindf";
                DESCRIPTION = "jmartindf's self-hosted code forge";
              };

            }; # end `forgejo` settings block
          }; # end `forgejo` block

        }; # end `services` block

        # Taken from [@orangci](https://github.com/orangci)
        # [forgejo.nix](https://github.com/orangci/dots/commit/c84ee0a6116592961a5d935d4c961f11eb419c59)
        systemd.services.forgejo.preStart =
          let
            theme = pkgs.fetchzip {
              url = "https://github.com/catppuccin/gitea/releases/download/v1.0.2/catppuccin-gitea.tar.gz";
              sha256 = "sha256-rZHLORwLUfIFcB6K9yhrzr+UwdPNQVSadsw6rg8Q7gs=";
              stripRoot = false;
            };
            inherit (nixOScfg.services.forgejo) stateDir;
          in
          lib.mkAfter ''
            rm -rf ${stateDir}/custom/public/assets
            mkdir -p ${stateDir}/custom/public/assets/css
            cp -r --no-preserve=mode,ownership ${theme}/* ${stateDir}/custom/public/assets/css
            mkdir -p ${stateDir}/custom/public/assets/img
            cp -r --no-preserve=mode,ownership ${./gitea/public/assets/img}/* ${stateDir}/custom/public/assets/img
          '';

      }; # end Nix OS module config block

    }; # end `forgejo` Nix OS module
}
