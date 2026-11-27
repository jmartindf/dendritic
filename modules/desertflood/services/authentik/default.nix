{ df, inputs, ... }:
{
  df.services.authentik = {

    traefik-apps = {
      authentik = {
        rule = "Host(`authentik.desertflood.link`) || Host(`sso.desertflood.link`)";
        url = "https://127.0.0.1:9443";
        middlewares = "chain-no-auth@file";
        certresolver = "web";
        serversTransport = "skipVerify@file";
      };
    };

    includes = [ df.services.postgresql ];

    nixos =
      {
        config,
        ...
      }:
      let
        nixOScfg = config;
      in
      {
        imports = [
          inputs.authentik-nix.nixosModules.default
        ];

        config = {

          age.secrets.authentik-env = {
            rekeyFile = ./authentik.env.age;
          };

          services = {
            authentik = {

              enable = true;

              environmentFile = nixOScfg.age.secrets.authentik-env.path;

              settings = {

                postgresql = {
                  user = "authentik";
                  name = "authentik";
                };

                email = {
                  port = 587;
                  use_tls = true;
                  use_ssl = false;
                  from = "Authentik <admin@thosemartins.family>";
                }; # end `settings.email`

                disable_startup_analytics = true;
                disable_update_check = true;
                avatars = "gravatar,initials";

              }; # end `authentik.settings`

              nginx.enable = false;

            }; # end `services.authentik`

            postgresql = {

              ensureDatabases = [ "authentik" ];

              ensureUsers = [
                {
                  name = "authentik";
                  ensureDBOwnership = true;
                }
              ];

            }; # end `services.postgresql`

          }; # end `services`

          systemd.services = {

            authentik-migrate = {
              requires = [ "postgresql.target" ];
              after = [ "postgresql.target" ];
            };

            authentik = {
              requires = [ "postgresql.target" ];
              after = [ "postgresql.target" ];
            };
          };

        }; # end `df.services.authentik.nixos.config`

      }; # end `df.services.authentik.nixos`

  }; # end aspect definition

  flake-file.inputs.authentik-nix = {
    # url = "github:MarcelCoding/authentik-nix/ak-update";
    url = "github:nix-community/authentik-nix/version/2026.8.6";
    # url = "github:jmartindf/authentik-nix/version/2026.2.3";
    inputs = {
      # nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      flake-compat.follows = "flake-compat";
      flake-utils.follows = "flake-utils";
      systems.follows = "systems";
    };
  };
}
