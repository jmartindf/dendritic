{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.grafana =
    { config, pkgs, ... }:
    let
      cfg = config;
      netCfg = cfg.desertflood.networking;
      promCfg = cfg.services.prometheus;
      grafanaUser = "grafana";
      grafanaGroup = "grafana";
    in
    {
      options = {
      };

      config =
        let
          parentCredFolder = "${cfg.services.grafana.dataDir}/secrets";
          credFolder = "${parentCredFolder}/credentials";
        in
        {

          age.secrets = {
            grafana-password = {
              rekeyFile = ./grafana-password.age;
              owner = grafanaUser;
              group = grafanaGroup;
            };
            grafana-client-secret = {
              rekeyFile = ./grafana-client-secret.age;
              owner = grafanaUser;
              group = grafanaGroup;
            };
          };

          desertflood = {
            shared-secrets.smtp.enable = true;
            services.postgresql.enable = true;
            networking.services.grafana = { };
          };

          services = {

            postgresql = {
              ensureDatabases = [ grafanaUser ];
              ensureUsers = [
                {
                  name = grafanaUser;
                  ensureDBOwnership = true;
                }
              ];
            };

            grafana =
              let
                svcConfig = netCfg.services.grafana;
              in
              {
                enable = true;

                settings = {
                  server = {
                    http_addr = "127.0.0.1";
                    http_port = 3000;
                    domain = "${svcConfig.fqdn}";
                    root_url = "${svcConfig.fullURL}";
                    serve_from_sub_path = if svcConfig.path != "" then true else false;
                  };

                  database = {
                    host = "/run/postgresql";
                    name = grafanaUser;
                    type = "postgres";
                    user = grafanaUser;
                  };

                  smtp = {
                    enabled = true;
                    host = "$__file{${credFolder}/smtp-server}:587";
                    user = "$__file{${credFolder}/smtp-user}";
                    password = "$__file{${credFolder}/smtp-password}";
                    startTLS_policy = "MandatoryStartTLS";
                    from_address = "admin@desertflood.com";
                    from_name = "Grafana Desertflood";
                  };

                  security = {
                    admin_user = "gfadmin";
                    admin_password = "$__file{${cfg.age.secrets.grafana-password.path}}";
                    admin_email = flakeCfg.desertflood.defaultUser.emails.family.email;
                    cookie_secure = true;
                  };

                  auth = {
                    oauth_allow_insecure_email_lookup = false; # True to match existing users by email address
                  };

                  "auth.generic_oauth" = {
                    enabled = true;
                    auto_login = true;
                    allow_sign_up = true;
                    use_refresh_token = true;
                    allow_assign_grafana_admin = true;
                    name = "Authentik Desertflood";
                    client_id = "szq3K7BWLSsPDkyRpw7AnxPbroFXoT6pKhdbVYSX";
                    client_secret = "$__file{${cfg.age.secrets.grafana-client-secret.path}}";
                    scopes = [
                      "openid"
                      "email"
                      "profile"
                      "offline_access"
                    ];
                    auth_url = "https://sso.desertflood.link/application/o/authorize/";
                    token_url = "https://sso.desertflood.link/application/o/token/";
                    api_url = "https://sso.desertflood.link/application/o/userinfo/";
                    signout_redirect_url = "https://sso.desertflood.link/application/o/grafana/end-session/";
                    role_attribute_path = "contains(groups[*], 'Grafana Server Admins') && 'GrafanaAdmin' || contains(groups[*], 'Grafana Admins') && 'Admin' || contains(groups[*], 'Grafana Editors') && 'Editor' || 'Viewer'";
                    login_attribute_path = "preferred_username";
                    name_attribute_path = "given_name";
                    email_attribute_path = "email";
                    email_attribute_name = "email";
                  };
                };

                provision = {
                  enable = true;

                  datasources.settings.datasources = [
                    {
                      orgId = 1;
                      name = "prometheus";
                      type = "prometheus";
                      httpMethod = "POST";
                      prometheusVersion = "> 2.50.x";
                      prometheusType = "Prometheus";
                      cacheLevel = "Low";
                      tlsSkipVerify = false;
                      manageAlerts = true;
                      url = "https://${promCfg.listenAddress}:${builtins.toString promCfg.port}/prometheus/";
                    }
                  ];

                  dashboards.settings.providers = [
                    {
                      name = "default";
                      orgId = 1;
                      type = "file";
                      disableDeletion = false;
                      updateIntervalSeconds = 10;
                      allowUiUpdates = true;
                      options = {
                        path = ./dashboards;
                        foldersFromFilesStructure = true;
                      };
                    }
                  ];

                }; # end `provision` block

              }; # end `grafana` block

          }; # end `services` block

          systemd.services.grafana = {
            serviceConfig = {

              LoadCredential = [
                "smtp-server:${cfg.age.secrets.smtp-server.path}"
                "smtp-user:${cfg.age.secrets.smtp-user.path}"
                "smtp-password:${cfg.age.secrets.smtp-password.path}"
              ];

              ExecStartPre = "+${
                (pkgs.writeShellScript "grafana-prestart-credentials" # bash
                  ''
                    mkdir -p ${parentCredFolder}
                    rm -f ${credFolder}
                    chown -R ${grafanaUser}:${grafanaGroup} ${parentCredFolder}
                    chmod -f 0700 ${parentCredFolder}
                    ln -s $CREDENTIALS_DIRECTORY ${credFolder}
                  ''
                )
              }";

            };
          };

        }; # end Nix OS module config block

    }; # end `grafana` Nix OS module
}
