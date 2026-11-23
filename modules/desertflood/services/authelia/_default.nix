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
        autheliaUser = "authelia-main";

        # settingsFormat = (pkgs.formats.json { });

        svcsConfig = nixOScfg.desertflood.services;
        netConfig = nixOScfg.desertflood.networking;

        mkAutheliaSecrets =
          secretHolder: names:
          lib.genAttrs names (name: {
            rekeyFile = ./secrets/${name}.age;
            owner = secretHolder;
            group = secretHolder;
          });
      in
      {

        imports = [ ];

        options = {
          desertflood.services.authelia = {

            enable = lib.mkEnableOption {
              default = false;
              description = "Whether to enable Authelia authentication and authorization server";
            };
          }; # end `desertflood.services.authelia`
        }; # end NixOS module `options`

        config = lib.mkIf svcsConfig.authelia.enable {

          age.secrets = mkAutheliaSecrets autheliaUser [
            "authelia-jwt-secret"
            "authelia-oidc-issuer-private-key"
            "authelia-oidc-hmac-secret"
            "authelia-session-secret"
            "authelia-storage-encryption-key"
            "authelia-manysecrets_yml"
          ];

          desertflood = {
            networking.services.authelia = { };

            services.authelia = { };

            services.postgresql.enable = true;
          };

          services.postgresql = {
            authentication = ''
              local ${autheliaUser} all peer map=authelia-users
            '';

            identMap = # identMap
              ''
                authelia-users root ${autheliaUser}
                authelia-users ${autheliaUser} ${autheliaUser}
              '';

            ensureDatabases = [ autheliaUser ];
            ensureUsers = [
              {
                name = autheliaUser;
                ensureDBOwnership = true;
              }
            ];
          };

          services.authelia = {

            instances.main = {

              enable = true;
              settingsFiles = [ nixOScfg.age.secrets.authelia-manysecrets_yml.path ];

              secrets = {
                jwtSecretFile = nixOScfg.age.secrets.authelia-jwt-secret.path;
                storageEncryptionKeyFile = nixOScfg.age.secrets.authelia-storage-encryption-key.path;
                sessionSecretFile = nixOScfg.age.secrets.authelia-session-secret.path;
                oidcIssuerPrivateKeyFile = nixOScfg.age.secrets.authelia-oidc-issuer-private-key.path;
                oidcHmacSecretFile = nixOScfg.age.secrets.authelia-oidc-hmac-secret.path;
              };

              settings = {
                ntp = {
                  disable_startup_check = true;
                };
                server = {
                  address = "tcp://127.0.0.1:9091/";
                };
                log = {
                  level = "info";
                  format = "text";
                  # file_path = "/var/log/authelia/authelia.log";
                  # keep_stdout = true;
                };
                totp = {
                  issuer = "desertflood.com";
                  period = 30;
                  skew = 1;
                };
                authentication_backend = {
                  ldap = {
                    implementation = "lldap";
                    address = "ldap://127.0.0.1:3890";
                    base_dn = "DC=desertflood,DC=com";
                    user = "UID=authelia,OU=people,DC=desertflood,DC=com";
                  };
                };
                password_policy = {
                  standard.enabled = false;
                  zxcvbn = {
                    enabled = true;
                    min_score = 3;
                  };
                };
                access_control = {
                  default_policy = "deny";
                  rules = [
                    {
                      domain = [ "controlpi.h.thosemartins.family" ];
                      resources = [ "^/api([/?].*)?$" ];
                      policy = "bypass";
                    }
                    {
                      domain = [ "apps.thosemartins.family" ];
                      subject = [ [ "group:homelab_users" ] ];
                      policy = "one_factor";
                    }
                    {
                      domain = [
                        "bragibooks.h.thosemartins.family"
                        "dozzle.h.thosemartins.family"
                        "movies-anime.h.thosemartins.family"
                        "movies.h.thosemartins.family"
                        "openbooks.h.thosemartins.family"
                        "prowlarr.h.thosemartins.family"
                        "qbt.h.thosemartins.family"
                        "sabnzbd.h.thosemartins.family"
                        "syncthing.h.thosemartins.family"
                        "traefik.h.thosemartins.family"
                        "tv-anime.h.thosemartins.family"
                        "tv.h.thosemartins.family"
                        "underworld.h.thosemartins.family"
                        "everest.df.fyi"
                      ];
                      subject = [ [ "group:homelab_admins" ] ];
                      policy = "two_factor";
                    }
                  ];
                };
                session = {
                  name = "authelia_session";
                  expiration = "1h";
                  inactivity = "5m";
                  remember_me = "1M";
                  cookies = [
                    {
                      domain = "thosemartins.family";
                      authelia_url = "https://idm.thosemartins.family/";
                      default_redirection_url = "https://apps.thosemartins.family";
                    }
                    {
                      domain = "desertflood.link";
                      authelia_url = "https://idm.desertflood.link/";
                    }
                    {
                      domain = "df.fyi";
                      authelia_url = "https://idm.df.fyi/";
                    }
                  ];
                  redis = {
                    host = "127.0.0.1";
                    port = 6379;
                  };
                };
                regulation = {
                  max_retries = 3;
                  find_time = 300;
                  ban_time = 600;
                };
                storage.postgres = {
                  address = "unix:///run/postgresql";
                  database = autheliaUser;
                  username = autheliaUser;
                };
                notifier = {
                  disable_startup_check = false;
                  smtp = {
                    sender = "Authelia <admin@thosemartins.family>";
                    identifier = "everest";
                    subject = "[Authelia] {title}";
                    startup_check_address = "test@authelia.com";
                    disable_require_tls = false;
                    disable_starttls = false;
                    disable_html_emails = false;
                    tls = {
                      skip_verify = false;
                    };
                  };
                };
                definitions = {
                  user_attributes = {
                    audiobookshelf_roles = {
                      expression = "( \"abs_admin\" in groups ) ? [\"admin\"]: ( \"abs_user\" in groups ? [\"user\"]: [\"guest\"])";
                    };
                  };
                };
                identity_providers = {
                  oidc = {
                    jwks = [ { use = "sig"; } ];
                    lifespans = {
                      access_token = "2d";
                      refresh_token = "3d";
                    };
                    cors = {
                      endpoints = [
                        "authorization"
                        "token"
                        "revocation"
                        "introspection"
                        "userinfo"
                      ];
                      allowed_origins_from_client_redirect_uris = true;
                      allowed_origins = [
                        "https://idm.desertflood.link"
                        "https://idm.thosemartins.family"
                        "https://idm.df.fyi"
                      ];
                    };
                    claims_policies = {
                      audiobookshelf_policy = {
                        custom_claims = {
                          audiobookshelf_groups = {
                            attribute = "audiobookshelf_roles";
                          };
                        };
                      };
                    };
                    scopes = {
                      audiobookshelf_groups = {
                        claims = [ "audiobookshelf_groups" ];
                      };
                    };
                  };
                };
              };
            };

          }; # end `services.authelia`

          systemd.services.authelia-main = {

            requires = [
              "lldap.service"
              "postgresql.service"
              "redis.service"
            ];

            after = [
              "lldap.service"
              "postgresql.service"
              "redis.service"
            ];
          };
        }; # end NixOS `authelia` module

      }; # end NixOS module `config`

  }; # End flake-parts `config`

}
