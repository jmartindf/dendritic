{ inputs, ... }:
{

  config = {

    flake.modules.nixos.authentik =
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
        imports = [
          inputs.authentik-nix.nixosModules.default
        ];

        options = {
          desertflood = {
            services = {
              authentik = {
                enable = lib.mkEnableOption "Authentik, a self-hosted, open source identity provider";
              };
            };
          };
        }; # end `flake.modules.nixos.authentik.options`

        config = lib.mkIf nixOScfg.desertflood.services.authentik.enable {

          age.secrets.authentik-env = {
            rekeyFile = ./authentik.env.age;
          };

          desertflood.services.postgresql.enable = true;

          services = {
            authentik = {

              enable = true;

              environmentFile = nixOScfg.age.secrets.authentik-env.path;

              settings = {

                postgresql = {
                  user = "authentik";
                  name = "authentik";
                };

                redis = {
                  host = "127.0.0.1";
                  port = 6380;
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

            redis.servers.authentik.port = lib.mkForce 6380;

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
              requires = [ "postgresql.service" ];
              after = [ "postgresql.service" ];
            };

            authentik = {
              after = [ "postgresql.service" ];
            };
          };

        }; # end `flake.modules.nixos.authentik.config`

      }; # end `flake.modules.nixos.authentik`

  }; # end flake-parts module config

}
