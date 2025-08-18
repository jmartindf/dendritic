{ config, ... }:
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

              repository = {
                DEFAULT_PUSH_CREATE_PRIVATE = true;
                ENABLE_PUSH_CREATE_USER = true;
                DEFAULT_REPO_UNITS = "repo.code,repo.releases,repo.issues,repo.pulls,repo.projects,repo.packages";
              };

              database = {
                user = "forgejo";
                type = "postgres";
                name = "forgejo";
                createDatabase = false;
                host = "127.0.0.1";
              };

              server = {
                HTTP_ADDR = "127.0.0.1";
                HTTP_PORT = 3030;
                DOMAIN = "${netCfg.services.forgejo.fqdn}";
                ROOT_URL = "${netCfg.services.forgejo.fullURL}";
                SSH_DOMAIN = "${netCfg.services.forgejo.fqdn}";
                DISABLE_SSH = true;
                OFFLINE_MODE = false;
              };

            }; # end `forgejo` settings block
          }; # end `forgejo` block

        }; # end `services` block

      }; # end Nix OS module config block

    }; # end `forgejo` Nix OS module
}
