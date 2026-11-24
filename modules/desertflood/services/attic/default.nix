{ df, ... }:
let
  atticPort = 7082;
  atticHost = "attic.desertflood.com";
in
{

  df.services.attic = {

    includes = [ df.services.postgresql ];

    traefik-apps = {
      attic = {
        rule = "Host(`${atticHost}`)";
        url = "http://127.0.0.1:${toString atticPort}";
      };
    };

    nixos =
      { config, ... }:
      let
        nixOScfg = config;
        atticUser = nixOScfg.services.atticd.user;
      in
      {

        age.secrets.atticd-env = {
          rekeyFile = ./atticd.env.age;
          # owner = atticUser;
          # group = atticUser;
        };

        services.postgresql = {
          ensureUsers = [
            {
              name = atticUser;
              ensureDBOwnership = true;
            }
          ];
          ensureDatabases = [ atticUser ];
        }; # end services.postgresql

        # users.users.${atticUser} = {
        #   home = "/var/lib/${atticUser}";
        #   useDefaultShell = true;
        #   group = atticUser;
        #   isSystemUser = true;
        # };
        # users.groups.${atticUser} = { };

        services.atticd = {
          enable = true;
          mode = "monolithic";

          environmentFile = nixOScfg.age.secrets.atticd-env.path;

          settings = {
            listen = "127.0.0.1:${toString atticPort}";
            allowed-hosts = [ atticHost ];
            api-endpoint = "https://${atticHost}/";

            require-proof-of-possession = true;

            chunking = {
              avg-size = 196608;
              max-size = 786432;
              min-size = 49152;
              nar-size-threshold = 196608;
            };

            database = {
              url = "postgres://${atticUser}/${atticUser}?host=/run/postgresql";
            };

            storage = {
              bucket = "nix-attic";
              endpoint = "https://s3.us-west-001.backblazeb2.com";
              region = "us-west-001";
              type = "s3";
            };

            garbage-collection = {
              interval = "12 hours"; # Default
              default-retention-period = "6 months"; # Default, can be changed on a per cache basis
            };

          }; # end services.atticd.settings

        }; # end services.atticd

        systemd.services.atticd = {
          after = [ "postgresql.target" ];
          requires = [ "postgresql.target" ];
        };

      }; # end NixOS module `config`

  }; # end NixOS `attic` module
}
