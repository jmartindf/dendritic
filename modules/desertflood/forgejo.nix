{ config, lib, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.forgejo =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      netCfg = nixOScfg.desertflood.networking;
    in
    {
      options = {
      };

      config =
        let
          forgejoUser = nixOScfg.services.forgejo.user;
          forgejoGroup = nixOScfg.services.forgejo.group;
        in
        {

          age.secrets = {
            forgejo-password-sunfish = {
              rekeyFile = ./forgejo-password-sunfish.age;
              owner = forgejoUser;
              group = forgejoGroup;
            };
            forgejo-password-mirrors = {
              rekeyFile = ./forgejo-password-mirrors.age;
              owner = forgejoUser;
              group = forgejoGroup;
            };
            forgejo-password-jmartindf = {
              rekeyFile = ./forgejo-password-jmartindf.age;
              owner = forgejoUser;
              group = forgejoGroup;
            };
            # forgejo-password-database = {
            #   rekeyFile = ./forgejo-password-database.age;
            #   generator.script = "passphrase";
            #   owner = forgejoUser;
            #   group = forgejoGroup;
            # };
          };

          desertflood.networking.services.forgejo = { };

          services = {

            postgresql = {
              enable = true;
              package = pkgs.postgresql_17;
              ensureDatabases = [ forgejoUser ];
              ensureUsers = [
                {
                  name = forgejoUser;
                  ensureDBOwnership = true;
                }
              ];
            };

            forgejo = {
              enable = true;

              database = {
                user = forgejoUser;
                type = "postgres";
                name = forgejoUser;
                # host = "127.0.0.1";
                createDatabase = false;
                socket = "/run/postgresql";
                # passwordFile = nixOScfg.age.secrets.forgejo-password-database.path;
              };

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
                  THEMES = lib.concatStringsSep "," [
                    "catppuccin-mocha-rosewater"
                    "catppuccin-mocha-flamingo"
                    "catppuccin-mocha-pink"
                    "catppuccin-mocha-mauve"
                    "catppuccin-mocha-red"
                    "catppuccin-mocha-maroon"
                    "catppuccin-mocha-peach"
                    "catppuccin-mocha-yellow"
                    "catppuccin-mocha-green"
                    "catppuccin-mocha-teal"
                    "catppuccin-mocha-sky"
                    "catppuccin-mocha-sapphire"
                    "catppuccin-mocha-blue"
                    "catppuccin-mocha-lavender"
                    "catppuccin-rosewater-auto"
                    "catppuccin-flamingo-auto"
                    "catppuccin-pink-auto"
                    "catppuccin-mauve-auto"
                    "catppuccin-red-auto"
                    "catppuccin-maroon-auto"
                    "catppuccin-peach-auto"
                    "catppuccin-yellow-auto"
                    "catppuccin-green-auto"
                    "catppuccin-teal-auto"
                    "catppuccin-sky-auto"
                    "catppuccin-sapphire-auto"
                    "catppuccin-blue-auto"
                    "catppuccin-lavender-auto"
                    "forgejo-auto"
                  ];
                };

                "ui.meta" = {
                  AUTHOR = "jmartindf";
                  DESCRIPTION = "jmartindf's self-hosted code forge";
                };

              }; # end `forgejo` settings block
            }; # end `forgejo` block

          }; # end `services` block

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
