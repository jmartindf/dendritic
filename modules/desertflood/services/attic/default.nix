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

        imports = [ ];

        options = {
          desertflood.services.attic = {

            enable = lib.mkEnableOption {
              default = false;
              description = "Whether to enable the atticd, the Nix Binary Cache server.";
            };

            port = lib.mkOption {
              type = lib.types.str;
              default = "7082";
              description = "Local port to listen on";
            };

          };
        }; # end NixOS module `options`

        config =
          let
            svcsConfig = nixOScfg.desertflood.services;
            netConfig = nixOScfg.desertflood.networking;
            url =
              let
                u = netConfig.services.attic.fullURL;
                len = builtins.stringLength u;
              in
              if ((builtins.substring (len - 1) len u) != "/") then "${u}/" else "${u}";
            atticUser = nixOScfg.services.atticd.user;
          in
          lib.mkIf nixOScfg.desertflood.services.attic.enable {

            age.secrets.atticd-env = {
              rekeyFile = ./atticd.env.age;
              # owner = atticUser;
              # group = atticUser;
            };

            desertflood.networking.services.attic = { };

            services.postgresql = {
              enable = true;

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
                listen = "127.0.0.1:${svcsConfig.attic.port}";
                allowed-hosts = [ netConfig.services.attic.fqdn ];
                api-endpoint = "${url}";

                require-proof-of-possession = true;

                chunking = {
                  avg-size = 65536;
                  max-size = 262144;
                  min-size = 16384;
                  nar-size-threshold = 65536;
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

  }; # End flake-parts `config`

}
